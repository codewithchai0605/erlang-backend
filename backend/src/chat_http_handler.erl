%% @doc Plain HTTP endpoints (JSON): health, auth, profile. Chat traffic does NOT use this module.
%% Route atoms come from chat_http_listener:routes/0. Handlers stay thin: parse -> call domain -> map the
%% domain result to an HTTP status.
-module(chat_http_handler).
-behaviour(cowboy_handler).
-include("chat.hrl").
-export([init/2, origin_allowed/1, client_ip/1]).
-define(MAX_BODY, 16384).

init(Req0, Route) ->
  chat_metrics:inc(http_requests_total),
  Method = cowboy_req:method(Req0),
  case Method of
    <<"OPTIONS">> -> {ok, preflight(Req0), Route};
    _ ->
      {Status, Headers, Body, Req1} =
        try handle(Route, Method, Req0)
        catch Class:Reason:Stack ->
          ?LOG_ERROR(#{event => http_handler_crash, route => Route, class => Class, reason => Reason, stack => Stack}),
          json(500, #{error => #{code => internal, message => <<"internal error">>}}, Req0)
        end,
      {ok, cowboy_req:reply(Status, maps:merge(cors(Req1), Headers), Body, Req1), Route}
  end.

%% ------------------------------------------------------------------ routes
handle(health, <<"GET">>, Req) -> json(200, #{status => ok}, Req);
handle(ready, <<"GET">>, Req) ->
  case chat_repo:ping() of
    ok -> json(200, #{status => ready}, Req);
    _ -> json(503, #{status => not_ready}, Req)
  end;
handle(metrics, <<"GET">>, Req) ->
  case is_loopback(Req) of
    true -> {200, #{<<"content-type">> => <<"text/plain; version=0.0.4">>}, chat_metrics:render(), Req};
    false -> fail(not_found, <<"not found">>, Req)
  end;

handle(register, <<"POST">>, Req0) ->
  with_json(Req0, fun(Map, Req) ->
    limited(Req, auth, fun() ->
      Params = #{username => str(<<"username">>, Map), password => str(<<"password">>, Map),
                 display_name => str(<<"display_name">>, Map)},
      auth_result(chat_auth:register(Params, device(Map)), 201, Req)
    end)
  end);
handle(login, <<"POST">>, Req0) ->
  with_json(Req0, fun(Map, Req) ->
    limited(Req, auth, fun() ->
      Params = #{username => str(<<"username">>, Map), password => str(<<"password">>, Map)},
      auth_result(chat_auth:login(Params, device(Map)), 200, Req)
    end)
  end);
handle(refresh, <<"POST">>, Req0) ->
  with_json(Req0, fun(Map, Req) ->
    limited(Req, auth, fun() ->
      case chat_auth:refresh(str(<<"refresh_token">>, Map)) of
        {ok, #{tokens := T}} -> json(200, #{tokens => T}, Req);
        {error, Reason} -> fail_reason(Reason, Req)
      end
    end)
  end);
handle(logout, <<"POST">>, Req) ->
  authed(Req, fun(#{user_id := U, session_id := S}) ->
    ok = chat_auth:logout(U, S),
    {204, #{}, <<>>, Req}
  end);
handle(logout_all, <<"POST">>, Req) ->
  authed(Req, fun(#{user_id := U}) ->
    case chat_auth:logout_all(U) of
      ok -> {204, #{}, <<>>, Req};
      {error, Reason} -> fail_reason(Reason, Req)
    end
  end);
handle(me, <<"GET">>, Req) ->
  authed(Req, fun(#{user_id := U}) ->
    case chat_users:get(U) of
      {ok, User} -> json(200, #{user => User}, Req);
      {error, Reason} -> fail_reason(Reason, Req)
    end
  end);
handle(me, <<"PATCH">>, Req0) ->
  authed(Req0, fun(#{user_id := U}) ->
    with_json(Req0, fun(Map, Req) ->
      case chat_users:update_display_name(U, str(<<"display_name">>, Map)) of
        {ok, User} -> json(200, #{user => User}, Req);
        {error, Reason} -> fail_reason(Reason, Req)
      end
    end)
  end);
handle(user_lookup, <<"GET">>, Req) ->
  authed(Req, fun(#{user_id := U}) ->
    limited(Req, {lookup, U}, fun() ->
      #{username := Name} = cowboy_req:match_qs([{username, [], <<>>}], Req),
      case chat_users:lookup(Name) of
        {ok, User} -> json(200, #{user => User}, Req);
        {error, Reason} -> fail_reason(Reason, Req)
      end
    end)
  end);
handle(_Route, _Method, Req) -> fail(method_not_allowed, <<"method not allowed">>, Req).

%% ------------------------------------------------------------------ helpers
auth_result({ok, #{user := User, tokens := Tokens}}, Status, Req) -> json(Status, #{user => User, tokens => Tokens}, Req);
auth_result({error, Reason}, _Status, Req) -> fail_reason(Reason, Req).

fail_reason({invalid, Field}, Req) -> fail(invalid_argument, iolist_to_binary(["invalid ", atom_to_list(Field)]), Req);
fail_reason(username_taken, Req) -> fail(conflict, <<"username already taken">>, Req);
fail_reason(invalid_credentials, Req) -> fail(unauthenticated, <<"invalid username or password">>, Req);
fail_reason(invalid_refresh, Req) -> fail(unauthenticated, <<"invalid refresh token">>, Req);
fail_reason(unauthenticated, Req) -> fail(unauthenticated, <<"authentication required">>, Req);
fail_reason(not_found, Req) -> fail(not_found, <<"not found">>, Req);
fail_reason(rate_limited, Req) -> fail(rate_limited, <<"too many requests">>, Req);
fail_reason(_Other, Req) -> fail(internal, <<"internal error">>, Req).

fail(Code, Message, Req) -> json(status(Code), #{error => #{code => Code, message => Message}}, Req).

status(invalid_argument) -> 400;
status(unauthenticated) -> 401;
status(not_found) -> 404;
status(method_not_allowed) -> 405;
status(conflict) -> 409;
status(payload_too_large) -> 413;
status(unsupported_media_type) -> 415;
status(rate_limited) -> 429;
status(_) -> 500.

json(Status, Term, Req) ->
  {Status, #{<<"content-type">> => <<"application/json">>, <<"cache-control">> => <<"no-store">>},
   iolist_to_binary(json:encode(Term)), Req}.

with_json(Req0, Fun) ->
  case cowboy_req:header(<<"content-type">>, Req0) of
    <<"application/json", _/binary>> ->
      case cowboy_req:read_body(Req0, #{length => ?MAX_BODY, period => 5000}) of
        {ok, Body, Req1} ->
          try json:decode(Body) of
            Map when is_map(Map) -> Fun(Map, Req1);
            _ -> fail(invalid_argument, <<"expected a JSON object">>, Req1)
          catch error:_ -> fail(invalid_argument, <<"invalid JSON">>, Req1)
          end;
        {more, _, Req1} -> fail(payload_too_large, <<"request body too large">>, Req1)
      end;
    _ -> fail(unsupported_media_type, <<"content-type must be application/json">>, Req0)
  end.

str(Key, Map) -> case maps:get(Key, Map, undefined) of V when is_binary(V) -> V; _ -> <<>> end.

device(Map) ->
  case maps:get(<<"device">>, Map, #{}) of
    D when is_map(D) -> #{platform => clip(str(<<"platform">>, D), 32, <<"unknown">>), label => clip(str(<<"label">>, D), 64, null)};
    _ -> #{platform => <<"unknown">>, label => null}
  end.

clip(<<>>, _Max, Default) -> Default;
clip(B, Max, _Default) -> binary:part(B, 0, min(byte_size(B), Max)).

limited(Req, Name, Fun) ->
  Key = case Name of {_, K} -> K; _ -> client_ip(Req) end,
  case chat_rate_limit:check(Name, Key, chat_config:get(rate_auth_per_min), 60000) of
    ok -> Fun();
    {error, rate_limited} -> fail(rate_limited, <<"too many requests">>, Req)
  end.

authed(Req, Fun) ->
  case cowboy_req:header(<<"authorization">>, Req) of
    <<"Bearer ", Token/binary>> ->
      case chat_auth:authenticate(Token) of
        {ok, Auth} -> Fun(Auth);
        _ -> fail(unauthenticated, <<"authentication required">>, Req)
      end;
    _ -> fail(unauthenticated, <<"authentication required">>, Req)
  end.

client_ip(Req) ->
  {Ip, _Port} = cowboy_req:peer(Req),
  iolist_to_binary(inet:ntoa(Ip)).

is_loopback(Req) ->
  case cowboy_req:peer(Req) of
    {{127, _, _, _}, _} -> true;
    {{0, 0, 0, 0, 0, 0, 0, 1}, _} -> true;
    _ -> false
  end.

%% ------------------------------------------------------------------ CORS / origin
%% Native clients send no Origin header and are always allowed. Browsers are allowed only from the
%% configured origins (CHAT_ALLOWED_ORIGINS).
origin_allowed(Req) ->
  case cowboy_req:header(<<"origin">>, Req) of
    undefined -> true;
    Origin -> lists:member(Origin, chat_config:get(allowed_origins))
  end.

cors(Req) ->
  case cowboy_req:header(<<"origin">>, Req) of
    undefined -> #{};
    Origin ->
      case lists:member(Origin, chat_config:get(allowed_origins)) of
        true -> #{<<"access-control-allow-origin">> => Origin, <<"vary">> => <<"origin">>};
        false -> #{}
      end
  end.

preflight(Req) ->
  case origin_allowed(Req) of
    true -> cowboy_req:reply(204, maps:merge(cors(Req), #{
              <<"access-control-allow-methods">> => <<"GET, POST, PATCH, OPTIONS">>,
              <<"access-control-allow-headers">> => <<"authorization, content-type">>,
              <<"access-control-max-age">> => <<"600">>}), Req);
    false -> cowboy_req:reply(403, Req)
  end.
