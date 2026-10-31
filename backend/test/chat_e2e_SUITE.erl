%% End-to-end tests against a REAL PostgreSQL. Skipped unless CHAT_TEST_DB_NAME/USER/PASSWORD are set.
%% The database should be disposable: tests create users with random names and leave them behind.
-module(chat_e2e_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([auth_flow/1, refresh_reuse_revokes_session/1, ws_requires_hello/1, ws_rejects_text_frames/1,
         ws_rejects_bad_token/1, chat_flow/1, non_member_is_denied/1]).
-define(PORT, 18182).

all() -> [auth_flow, refresh_reuse_revokes_session, ws_requires_hello, ws_rejects_text_frames,
          ws_rejects_bad_token, chat_flow, non_member_is_denied].

init_per_suite(Config) ->
  case {os:getenv("CHAT_TEST_DB_NAME"), os:getenv("CHAT_TEST_DB_USER"), os:getenv("CHAT_TEST_DB_PASSWORD")} of
    {N, U, P} when is_list(N), is_list(U), is_list(P) ->
      [os:putenv(K, V) || {K, V} <- [{"CHAT_DB_NAME", N}, {"CHAT_DB_USER", U}, {"CHAT_DB_PASSWORD", P},
                                     {"CHAT_DB_HOST", os:getenv("CHAT_TEST_DB_HOST", "127.0.0.1")},
                                     {"CHAT_RUN_MIGRATIONS", "true"}, {"CHAT_HTTP_PORT", integer_to_list(?PORT)}]],
      {ok, _} = application:ensure_all_started(chat),
      {ok, _} = application:ensure_all_started(inets),
      {ok, _} = application:ensure_all_started(gun),
      Config;
    _ -> {skip, "set CHAT_TEST_DB_NAME, CHAT_TEST_DB_USER and CHAT_TEST_DB_PASSWORD to run"}
  end.

end_per_suite(_) -> application:stop(chat), ok.

%% ------------------------------------------------------------------ HTTP helpers
post(Path, Map) -> post(Path, Map, []).
post(Path, Map, Headers) ->
  Url = "http://127.0.0.1:" ++ integer_to_list(?PORT) ++ Path,
  Body = iolist_to_binary(json:encode(Map)),
  {ok, {{_, Status, _}, _, Resp}} =
    httpc:request(post, {Url, Headers, "application/json", Body}, [], [{body_format, binary}]),
  {Status, case Resp of <<>> -> #{}; _ -> json:decode(Resp) end}.

username() -> iolist_to_binary(["u", binary:encode_hex(crypto:strong_rand_bytes(5), lowercase)]).

register_user() ->
  Name = username(),
  {201, #{<<"user">> := #{<<"id">> := Id}, <<"tokens">> := T}} =
    post("/api/v1/auth/register", #{username => Name, password => <<"correct horse">>, display_name => Name}),
  #{id => Id, name => Name, access => maps:get(<<"access_token">>, T), refresh => maps:get(<<"refresh_token">>, T)}.

%% ------------------------------------------------------------------ WebSocket helpers
ws_open() ->
  {ok, Conn} = gun:open("127.0.0.1", ?PORT, #{protocols => [http]}),
  {ok, _} = gun:await_up(Conn),
  Ref = gun:ws_upgrade(Conn, "/ws"),
  receive {gun_upgrade, Conn, Ref, [<<"websocket">>], _} -> {Conn, Ref}
  after 5000 -> ct:fail(ws_upgrade_timeout) end.

ws_send({Conn, Ref}, ReqId, Body) ->
  Bin = iolist_to_binary(chat_pb:encode_msg(#{request_id => ReqId, body => Body}, 'ClientEnvelope')),
  gun:ws_send(Conn, Ref, {binary, Bin}).

ws_recv({Conn, _}) ->
  receive
    {gun_ws, Conn, _, {binary, Bin}} -> chat_pb:decode_msg(Bin, 'ServerEnvelope');
    {gun_ws, Conn, _, {close, Code, _}} -> {closed, Code};
    {gun_ws, Conn, _, close} -> {closed, 1005}
  after 5000 -> timeout
  end.

ws_login(User) ->
  Ws = ws_open(),
  ws_send(Ws, <<"h">>, {hello, #{protocol_version => 1, access_token => maps:get(access, User)}}),
  #{body := {hello_ack, #{user_id := Id}}} = ws_recv(Ws),
  Id = maps:get(id, User),
  Ws.

%% ------------------------------------------------------------------ cases
auth_flow(_) ->
  U = register_user(),
  Name = maps:get(name, U),
  {409, _} = post("/api/v1/auth/register", #{username => Name, password => <<"correct horse">>, display_name => <<"x">>}),
  {401, _} = post("/api/v1/auth/login", #{username => Name, password => <<"wrong password">>}),
  {200, #{<<"tokens">> := T}} = post("/api/v1/auth/login", #{username => Name, password => <<"correct horse">>}),
  {200, #{<<"tokens">> := T2}} = post("/api/v1/auth/refresh", #{refresh_token => maps:get(<<"refresh_token">>, T)}),
  true = maps:get(<<"refresh_token">>, T2) =/= maps:get(<<"refresh_token">>, T),
  {400, _} = post("/api/v1/auth/register", #{username => <<"x">>, password => <<"short">>, display_name => <<"">>}).

refresh_reuse_revokes_session(_) ->
  U = register_user(),
  Old = maps:get(refresh, U),
  {200, #{<<"tokens">> := #{<<"refresh_token">> := New}}} = post("/api/v1/auth/refresh", #{refresh_token => Old}),
  {401, _} = post("/api/v1/auth/refresh", #{refresh_token => Old}),      %% reuse detected
  {401, _} = post("/api/v1/auth/refresh", #{refresh_token => New}).      %% whole session revoked

ws_requires_hello(_) ->
  Ws = ws_open(),
  ws_send(Ws, <<"1">>, {list_conversations, #{}}),
  #{body := {error, #{code := 'ERROR_CODE_UNAUTHENTICATED'}}} = ws_recv(Ws),
  {closed, 1008} = ws_recv(Ws).

ws_rejects_text_frames(_) ->
  {Conn, Ref} = Ws = ws_open(),
  gun:ws_send(Conn, Ref, {text, <<"{\"json\":true}">>}),
  {closed, 1003} = ws_recv(Ws).

ws_rejects_bad_token(_) ->
  Ws = ws_open(),
  ws_send(Ws, <<"h">>, {hello, #{protocol_version => 1, access_token => <<"nope">>}}),
  #{body := {error, #{code := 'ERROR_CODE_UNAUTHENTICATED'}}} = ws_recv(Ws),
  {closed, 1008} = ws_recv(Ws).

chat_flow(_) ->
  A = register_user(), B = register_user(),
  WsA = ws_login(A), WsB = ws_login(B),
  ws_send(WsA, <<"c">>, {create_direct, #{peer_user_id => maps:get(id, B)}}),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsA),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsB),         %% pushed to the peer

  Send = fun(Ws, Cm, Text) -> ws_send(Ws, Cm, {send_message, #{conversation_id => Conv, client_message_id => Cm, text => Text}}) end,
  Send(WsA, <<"m1">>, <<"hello">>),
  #{body := {accepted, #{seq := 1, message_id := MsgId, duplicate := false}}} = ws_recv(WsA),
  #{body := {new_message, #{seq := 1, text := <<"hello">>, sender_id := SenderA}}} = ws_recv(WsB),
  SenderA = maps:get(id, A),

  %% idempotent retry: same client_message_id -> same message, flagged duplicate, nothing re-pushed
  Send(WsA, <<"m1">>, <<"hello">>),
  #{body := {accepted, #{seq := 1, message_id := MsgId, duplicate := true}}} = ws_recv(WsA),

  %% delivery receipt flows back to the sender
  ws_send(WsB, <<"d">>, {ack_delivered, #{conversation_id => Conv, delivered_up_to_seq => 1}}),
  #{body := {receipt, #{delivered_up_to_seq := 1}}} = ws_recv(WsB),
  #{body := {receipt, #{user_id := UserB, delivered_up_to_seq := 1}}} = ws_recv(WsA),
  UserB = maps:get(id, B),

  %% B goes offline; A sends two more; B reconnects and syncs from its cursor
  {ConnB, _} = WsB, gun:close(ConnB),
  Send(WsA, <<"m2">>, <<"two">>), #{body := {accepted, #{seq := 2}}} = ws_recv(WsA),
  Send(WsA, <<"m3">>, <<"three">>), #{body := {accepted, #{seq := 3}}} = ws_recv(WsA),
  WsB2 = ws_login(B),
  ws_send(WsB2, <<"s">>, {sync_request, #{conversation_id => Conv, after_seq => 1, limit => 10}}),
  #{body := {batch, #{messages := [#{seq := 2}, #{seq := 3}], has_more := false}}} = ws_recv(WsB2),

  %% backward history, paged
  ws_send(WsB2, <<"hi">>, {history_request, #{conversation_id => Conv, before_seq => 0, limit => 2}}),
  #{body := {batch, #{messages := [#{seq := 2}, #{seq := 3}], has_more := true}}} = ws_recv(WsB2).

non_member_is_denied(_) ->
  A = register_user(), B = register_user(), C = register_user(),
  WsA = ws_login(A), WsC = ws_login(C),
  ws_send(WsA, <<"c">>, {create_direct, #{peer_user_id => maps:get(id, B)}}),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsA),
  ws_send(WsC, <<"s">>, {sync_request, #{conversation_id => Conv, after_seq => 0, limit => 10}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC),
  ws_send(WsC, <<"m">>, {send_message, #{conversation_id => Conv, client_message_id => <<"x1">>, text => <<"intruder">>}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC).
