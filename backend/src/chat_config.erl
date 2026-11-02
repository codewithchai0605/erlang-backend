%% @doc Validated runtime configuration read from environment variables (see .env.example).
%% Not a process: the result lives in persistent_term (write-once, read-many), so reads cost nothing and
%% there is no gen_server bottleneck. Secrets are never logged.
%%
%% Hosting-platform aliases (so the same image runs on a laptop, Docker Compose and Render/Neon):
%%   * PORT                              -> CHAT_HTTP_PORT   (Render injects PORT)
%%   * CHAT_DATABASE_URL / DATABASE_URL  -> CHAT_DB_HOST/PORT/NAME/USER/PASSWORD/SSL
%% Precedence for every value: explicit CHAT_* variable > derived from an alias > built-in default.
%% Empty variables count as unset (Docker Compose passes unset ${VARS} through as empty strings).
-module(chat_config).
-export([load/0, load/1, parse/1, get/1, parse_database_url/1]).
-define(KEY, {?MODULE, config}).

spec() ->
  [{http_bind, "CHAT_HTTP_BIND", ip, "127.0.0.1"},
   {http_port, "CHAT_HTTP_PORT", {int, 1, 65535}, "8080"},
   {allowed_origins, "CHAT_ALLOWED_ORIGINS", origins, ""},
   {db_host, "CHAT_DB_HOST", string, "127.0.0.1"},
   {db_port, "CHAT_DB_PORT", {int, 1, 65535}, "5432"},
   {db_name, "CHAT_DB_NAME", string, required},
   {db_user, "CHAT_DB_USER", string, required},
   {db_password, "CHAT_DB_PASSWORD", string, required},
   {db_ssl, "CHAT_DB_SSL", {enum, [{"disable", disable}, {"require", require}, {"verify", verify}]}, "disable"},
   {db_pool_size, "CHAT_DB_POOL_SIZE", {int, 1, 200}, "10"},
   {run_migrations, "CHAT_RUN_MIGRATIONS", bool, "true"},
   {access_ttl_s, "CHAT_ACCESS_TOKEN_TTL_SECONDS", {int, 60, 86400}, "900"},
   {refresh_ttl_s, "CHAT_REFRESH_TOKEN_TTL_SECONDS", {int, 3600, 31536000}, "2592000"},
   {max_ws_message_bytes, "CHAT_MAX_WS_MESSAGE_BYTES", {int, 1024, 1048576}, "65536"},
   {max_text_chars, "CHAT_MAX_MESSAGE_TEXT_CHARS", {int, 1, 20000}, "4000"},
   {max_connections, "CHAT_MAX_CONNECTIONS", {int, 1, 1000000}, "10000"},
   {max_group_members, "CHAT_MAX_GROUP_MEMBERS", {int, 3, 1000}, "100"},
   {rate_auth_per_min, "CHAT_RATE_AUTH_PER_MINUTE", {int, 1, 100000}, "20"},
   {rate_send_per_min, "CHAT_RATE_SEND_PER_MINUTE", {int, 1, 100000}, "120"},
   {rate_group_per_min, "CHAT_RATE_GROUP_PER_MINUTE", {int, 1, 100000}, "30"},
   {rate_typing_per_min, "CHAT_RATE_TYPING_PER_MINUTE", {int, 1, 100000}, "120"},
   {presence_grace_ms, "CHAT_PRESENCE_GRACE_MS", {int, 0, 600000}, "5000"},
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
%% Returns {ok, ConfigMap} or {error, [{EnvName, missing | invalid}]} (names only, never values).
parse(Lookup0) ->
  {Lookup, AliasProblems} = with_aliases(Lookup0),
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
  case AliasProblems ++ lists:reverse(Problems) of
    [] -> {ok, Cfg};
    All -> {error, All}
  end.

%% ------------------------------------------------------------------ aliases
%% Wraps Lookup so that (1) empty strings read as "not set" and (2) values derived from PORT and from a
%% database URL fill in for CHAT_HTTP_PORT / CHAT_DB_* that were not set explicitly.
with_aliases(Lookup0) ->
  Set = fun(Env) -> case Lookup0(Env) of false -> false; "" -> false; V -> V end end,
  {Derived, Problems} = derive(Set),
  Lookup = fun(Env) ->
             case Set(Env) of
               false -> maps:get(Env, Derived, false);
               V -> V
             end
           end,
  {Lookup, Problems}.

derive(Set) ->
  Port = case Set("PORT") of false -> #{}; P -> #{"CHAT_HTTP_PORT" => P} end,
  case first_set(Set, ["CHAT_DATABASE_URL", "DATABASE_URL"]) of
    none -> {Port, []};
    {Name, Url} ->
      case parse_database_url(Url) of
        {ok, M} -> {maps:merge(Port, M), []};
        error -> {Port, [{Name, invalid}]}     %% report the variable NAME only; the URL holds the password
      end
  end.

first_set(_Set, []) -> none;
first_set(Set, [Name | Rest]) ->
  case Set(Name) of false -> first_set(Set, Rest); V -> {Name, V} end.

%% @doc Parse postgres://user:pass@host:port/dbname?sslmode=require into the CHAT_DB_* variable names.
%% sslmode mapping (libpq names): disable|allow -> disable; prefer|require -> require (TLS, certificate
%% NOT verified); verify-ca|verify-full -> verify. Unknown query parameters (e.g. channel_binding) are ignored.
-spec parse_database_url(string()) -> {ok, #{string() => string()}} | error.
parse_database_url(Url) ->
  try uri_string:parse(Url) of
    #{scheme := Scheme, host := Host, path := [$/ | Path]} = U
        when (Scheme =:= "postgres" orelse Scheme =:= "postgresql"), Host =/= "", Path =/= "" ->
      {User, Pass} = split_userinfo(maps:get(userinfo, U, "")),
      M0 = #{"CHAT_DB_HOST" => Host, "CHAT_DB_NAME" => pct_decode(Path)},
      M1 = put_if(M0, "CHAT_DB_PORT", case maps:get(port, U, undefined) of undefined -> ""; P -> integer_to_list(P) end),
      M2 = put_if(M1, "CHAT_DB_USER", User),
      M3 = put_if(M2, "CHAT_DB_PASSWORD", Pass),
      {ok, put_if(M3, "CHAT_DB_SSL", sslmode(maps:get(query, U, "")))};
    _ -> error
  catch _:_ -> error
  end.

split_userinfo(Info) ->
  case string:split(Info, ":") of
    [U, P] -> {pct_decode(U), pct_decode(P)};
    [U] -> {pct_decode(U), ""}
  end.

put_if(M, _K, "") -> M;
put_if(M, K, V) -> M#{K => V}.

sslmode("") -> "";
sslmode(Query) ->
  case uri_string:dissect_query(Query) of
    L when is_list(L) ->
      case lists:keyfind("sslmode", 1, L) of
        {_, Mode} -> ssl_for(Mode);
        false -> ""
      end;
    _ -> ""
  end.

ssl_for(M) when M =:= "disable"; M =:= "allow" -> "disable";
ssl_for(M) when M =:= "prefer"; M =:= "require" -> "require";
ssl_for(M) when M =:= "verify-ca"; M =:= "verify-full" -> "verify";
ssl_for(_) -> "".

%% Percent-decoding of URL userinfo/path (a password may legitimately contain %40 for '@', etc.).
pct_decode(S) -> pct_decode(S, []).
pct_decode([], Acc) -> lists:reverse(Acc);
pct_decode([$%, H1, H2 | T], Acc) ->
  case {hex(H1), hex(H2)} of
    {A, B} when is_integer(A), is_integer(B) -> pct_decode(T, [A * 16 + B | Acc]);
    _ -> pct_decode([H1, H2 | T], [$% | Acc])
  end;
pct_decode([C | T], Acc) -> pct_decode(T, [C | Acc]).

hex(C) when C >= $0, C =< $9 -> C - $0;
hex(C) when C >= $a, C =< $f -> C - $a + 10;
hex(C) when C >= $A, C =< $F -> C - $A + 10;
hex(_) -> error.

%% ------------------------------------------------------------------ value parsers
parse_value(string, S) when S =/= "" -> {ok, S};
parse_value(bool, "true") -> {ok, true};
parse_value(bool, "false") -> {ok, false};
parse_value({int, Min, Max}, S) ->
  try list_to_integer(S) of
    N when N >= Min, N =< Max -> {ok, N};
    _ -> error
  catch error:badarg -> error
  end;
parse_value({enum, Allowed}, S) ->
  case lists:keyfind(S, 1, Allowed) of {_, Atom} -> {ok, Atom}; false -> error end;
parse_value(ip, S) ->
  case inet:parse_address(S) of {ok, Ip} -> {ok, Ip}; _ -> error end;
parse_value(origins, S) ->
  {ok, [list_to_binary(string:trim(O)) || O <- string:tokens(S, ","), string:trim(O) =/= ""]};
parse_value(_, _) -> error.

get(Key) -> maps:get(Key, persistent_term:get(?KEY)).
