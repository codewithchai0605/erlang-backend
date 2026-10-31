%% @doc Validated runtime configuration read from environment variables (see .env.example).
%% Not a process: the result lives in persistent_term (write-once, read-many), so reads cost nothing and
%% there is no gen_server bottleneck. Secrets are never logged.
-module(chat_config).
-export([load/0, load/1, parse/1, get/1]).
-define(KEY, {?MODULE, config}).

spec() ->
  [{http_bind, "CHAT_HTTP_BIND", ip, "0.0.0.0"},
   {http_port, "CHAT_HTTP_PORT", {int, 1, 65535}, "10000"},
   {allowed_origins, "CHAT_ALLOWED_ORIGINS", origins, ""},
   {db_host, "CHAT_DB_HOST", string, "127.0.0.1"},
   {db_port, "CHAT_DB_PORT", {int, 1, 65535}, "5432"},
   {db_name, "CHAT_DB_NAME", string, required},
   {db_user, "CHAT_DB_USER", string, required},
   {db_password, "CHAT_DB_PASSWORD", string, required},
   {db_pool_size, "CHAT_DB_POOL_SIZE", {int, 1, 200}, "10"},
   {run_migrations, "CHAT_RUN_MIGRATIONS", bool, "true"},
   {access_ttl_s, "CHAT_ACCESS_TOKEN_TTL_SECONDS", {int, 60, 86400}, "900"},
   {refresh_ttl_s, "CHAT_REFRESH_TOKEN_TTL_SECONDS", {int, 3600, 31536000}, "2592000"},
   {max_ws_message_bytes, "CHAT_MAX_WS_MESSAGE_BYTES", {int, 1024, 1048576}, "65536"},
   {max_text_chars, "CHAT_MAX_MESSAGE_TEXT_CHARS", {int, 1, 20000}, "4000"},
   {max_connections, "CHAT_MAX_CONNECTIONS", {int, 1, 1000000}, "10000"},
   {rate_auth_per_min, "CHAT_RATE_AUTH_PER_MINUTE", {int, 1, 100000}, "20"},
   {rate_send_per_min, "CHAT_RATE_SEND_PER_MINUTE", {int, 1, 100000}, "120"},
   {hello_timeout_ms, "CHAT_WS_HELLO_TIMEOUT_MS", {int, 1000, 120000}, "10000"},
   {ws_idle_timeout_ms, "CHAT_WS_IDLE_TIMEOUT_MS", {int, 5000, 3600000}, "60000"},
   {slow_consumer_max_queue, "CHAT_WS_MAX_QUEUE", {int, 10, 1000000}, "1000"}].

load() -> load(fun os:getenv/1).

load(Lookup) ->
  case parse(Lookup) of
    {ok, Cfg} -> persistent_term:put(?KEY, Cfg), ok;
    {error, _} = E -> E
  end.

%% @doc Pure parser: Lookup :: fun(EnvName :: string()) -> string() | false.
parse(Lookup) ->
  {Cfg, Problems} = lists:foldl(
    fun({Key, Env, Type, Default}, {Acc, Errs}) ->
      Raw = case Lookup(Env) of false -> Default; V -> V end,
      case Raw of
        required -> {Acc, [{Env, missing} | Errs]};
        _ -> case parse_value(Type, Raw) of
               {ok, Val} -> {Acc#{Key => Val}, Errs};
               error -> {Acc, [{Env, invalid} | Errs]}
             end
      end
    end, {#{}, []}, spec()),
  case Problems of
    [] -> {ok, Cfg};
    _ -> {error, lists:reverse(Problems)}
  end.

parse_value(string, S) when S =/= "" -> {ok, S};
parse_value(bool, "true") -> {ok, true};
parse_value(bool, "false") -> {ok, false};
parse_value({int, Min, Max}, S) ->
  try list_to_integer(S) of
    N when N >= Min, N =< Max -> {ok, N};
    _ -> error
  catch error:badarg -> error
  end;
parse_value(ip, S) ->
  case inet:parse_address(S) of {ok, Ip} -> {ok, Ip}; _ -> error end;
parse_value(origins, S) ->
  {ok, [list_to_binary(string:trim(O)) || O <- string:tokens(S, ","), string:trim(O) =/= ""]};
parse_value(_, _) -> error.

get(Key) -> maps:get(Key, persistent_term:get(?KEY)).
