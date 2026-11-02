-module(chat_config_tests).
-include_lib("eunit/include/eunit.hrl").

env(Map) -> fun(K) -> maps:get(K, Map, false) end.
required() -> #{"CHAT_DB_NAME" => "n", "CHAT_DB_USER" => "u", "CHAT_DB_PASSWORD" => "p"}.

defaults_applied_test() ->
  {ok, Cfg} = chat_config:parse(env(required())),
  ?assertEqual(8080, maps:get(http_port, Cfg)),
  ?assertEqual({127, 0, 0, 1}, maps:get(http_bind, Cfg)),   %% loopback unless explicitly opened (Docker sets 0.0.0.0)
  ?assertEqual(disable, maps:get(db_ssl, Cfg)),
  ?assertEqual(true, maps:get(run_migrations, Cfg)),
  ?assertEqual([], maps:get(allowed_origins, Cfg)).

missing_required_reported_test() ->
  {error, Problems} = chat_config:parse(env(#{})),
  ?assert(lists:member({"CHAT_DB_NAME", missing}, Problems)),
  ?assert(lists:member({"CHAT_DB_PASSWORD", missing}, Problems)).

invalid_values_reported_test() ->
  {error, P} = chat_config:parse(env(maps:merge(required(), #{"CHAT_HTTP_PORT" => "99999", "CHAT_HTTP_BIND" => "nope",
                                                              "CHAT_RUN_MIGRATIONS" => "maybe"}))),
  ?assert(lists:member({"CHAT_HTTP_PORT", invalid}, P)),
  ?assert(lists:member({"CHAT_HTTP_BIND", invalid}, P)),
  ?assert(lists:member({"CHAT_RUN_MIGRATIONS", invalid}, P)).

origins_parsed_test() ->
  {ok, Cfg} = chat_config:parse(env(maps:merge(required(), #{"CHAT_ALLOWED_ORIGINS" => "http://a.test, http://b.test"}))),
  ?assertEqual([<<"http://a.test">>, <<"http://b.test">>], maps:get(allowed_origins, Cfg)).

%% ------------------------------------------------------------------ hosting-platform aliases
port_alias_test() ->
  {ok, C1} = chat_config:parse(env(maps:merge(required(), #{"PORT" => "10000"}))),
  ?assertEqual(10000, maps:get(http_port, C1)),
  %% an explicit CHAT_HTTP_PORT wins over PORT
  {ok, C2} = chat_config:parse(env(maps:merge(required(), #{"PORT" => "10000", "CHAT_HTTP_PORT" => "9000"}))),
  ?assertEqual(9000, maps:get(http_port, C2)).

empty_values_count_as_unset_test() ->
  {ok, Cfg} = chat_config:parse(env(maps:merge(required(), #{"CHAT_HTTP_PORT" => "", "CHAT_DB_HOST" => ""}))),
  ?assertEqual(8080, maps:get(http_port, Cfg)),
  ?assertEqual("127.0.0.1", maps:get(db_host, Cfg)).

database_url_fills_db_settings_test() ->
  Url = "postgresql://app_user:s%40cret%2Fpw@ep-x-pooler.eu-1.example.tech:6543/appdb?sslmode=require&channel_binding=require",
  {ok, Cfg} = chat_config:parse(env(#{"CHAT_DATABASE_URL" => Url})),
  ?assertEqual("ep-x-pooler.eu-1.example.tech", maps:get(db_host, Cfg)),
  ?assertEqual(6543, maps:get(db_port, Cfg)),
  ?assertEqual("appdb", maps:get(db_name, Cfg)),
  ?assertEqual("app_user", maps:get(db_user, Cfg)),
  ?assertEqual("s@cret/pw", maps:get(db_password, Cfg)),     %% percent-decoded
  ?assertEqual(require, maps:get(db_ssl, Cfg)).

database_url_alias_and_precedence_test() ->
  Url = "postgres://u:p@dbhost/dbname",
  {ok, A} = chat_config:parse(env(#{"DATABASE_URL" => Url})),          %% Render / Heroku style name
  ?assertEqual({"dbhost", 5432, "dbname", disable}, {maps:get(db_host, A), maps:get(db_port, A), maps:get(db_name, A), maps:get(db_ssl, A)}),
  {ok, B} = chat_config:parse(env(#{"DATABASE_URL" => Url, "CHAT_DB_HOST" => "override", "CHAT_DB_SSL" => "verify"})),
  ?assertEqual("override", maps:get(db_host, B)),                       %% explicit variable beats the URL
  ?assertEqual(verify, maps:get(db_ssl, B)).

sslmode_mapping_test() ->
  Mode = fun(M) ->
    {ok, C} = chat_config:parse(env(#{"CHAT_DATABASE_URL" => "postgres://u:p@h/d?sslmode=" ++ M})),
    maps:get(db_ssl, C)
  end,
  ?assertEqual([disable, disable, require, require, verify, verify],
               [Mode(M) || M <- ["disable", "allow", "prefer", "require", "verify-ca", "verify-full"]]).

bad_database_url_reports_name_not_value_test() ->
  {error, P} = chat_config:parse(env(#{"CHAT_DATABASE_URL" => "mysql://u:topsecret@h/d"})),
  ?assert(lists:member({"CHAT_DATABASE_URL", invalid}, P)),
  ?assertNot(lists:any(fun({_, V}) -> V =:= "mysql://u:topsecret@h/d" end, P)).

invalid_ssl_mode_reported_test() ->
  {error, P} = chat_config:parse(env(maps:merge(required(), #{"CHAT_DB_SSL" => "sometimes"}))),
  ?assert(lists:member({"CHAT_DB_SSL", invalid}, P)).

parse_database_url_test() ->
  ?assertMatch({ok, #{"CHAT_DB_HOST" := "h", "CHAT_DB_NAME" := "d"}}, chat_config:parse_database_url("postgres://h/d")),
  ?assertEqual(error, chat_config:parse_database_url("postgres://h")),        %% no database name
  ?assertEqual(error, chat_config:parse_database_url("not a url")).

