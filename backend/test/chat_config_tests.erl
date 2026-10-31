-module(chat_config_tests).
-include_lib("eunit/include/eunit.hrl").

env(Map) -> fun(K) -> maps:get(K, Map, false) end.
required() -> #{"CHAT_DB_NAME" => "n", "CHAT_DB_USER" => "u", "CHAT_DB_PASSWORD" => "p"}.

defaults_applied_test() ->
  {ok, Cfg} = chat_config:parse(env(required())),
  ?assertEqual(8080, maps:get(http_port, Cfg)),
  ?assertEqual({127, 0, 0, 1}, maps:get(http_bind, Cfg)),
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
