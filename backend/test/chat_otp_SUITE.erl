%% Supervision-tree behaviour. Needs NO database: migrations are disabled and the pool connects lazily.
-module(chat_otp_SUITE).
-include_lib("common_test/include/ct.hrl").
-define(HTTP, {ranch_listener_sup, chat_http}).   %% id of the child spec returned by ranch:child_spec/5
-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([tree_starts/1, listener_restarts_alone/1, pg_crash_restarts_dependents/1, bad_config_fails_fast/1]).

all() -> [tree_starts, listener_restarts_alone, pg_crash_restarts_dependents, bad_config_fails_fast].

init_per_suite(Config) ->
  [os:putenv(K, V) || {K, V} <- [{"CHAT_DB_NAME", "x"}, {"CHAT_DB_USER", "x"}, {"CHAT_DB_PASSWORD", "x"},
                                 {"CHAT_RUN_MIGRATIONS", "false"}, {"CHAT_HTTP_PORT", "18181"}]],
  {ok, _} = application:ensure_all_started(chat),
  Config.

end_per_suite(_) -> application:stop(chat), ok.

child_pid(Id) ->
  case lists:keyfind(Id, 1, supervisor:which_children(chat_sup)) of
    {Id, Pid, _, _} when is_pid(Pid) -> Pid;
    _ -> undefined
  end.

wait_new(Id, Old) -> wait_new(Id, Old, 50).
wait_new(_, _, 0) -> ct:fail(child_not_restarted);
wait_new(Id, Old, N) ->
  case child_pid(Id) of
    P when is_pid(P), P =/= Old -> P;
    _ -> timer:sleep(100), wait_new(Id, Old, N - 1)
  end.

tree_starts(_) ->
  true = is_pid(child_pid(chat_pg)),
  true = is_pid(child_pid(chat_rate_limit)),
  true = is_pid(child_pid(?HTTP)),
  {ok, Sock} = gen_tcp:connect("127.0.0.1", 18181, []),
  gen_tcp:close(Sock).

listener_restarts_alone(_) ->
  Pg = child_pid(chat_pg),
  Old = child_pid(?HTTP),
  exit(Old, kill),
  New = wait_new(?HTTP, Old),
  Pg = child_pid(chat_pg),               %% earlier siblings untouched (rest_for_one)
  true = is_pid(New).

pg_crash_restarts_dependents(_) ->
  OldRate = child_pid(chat_rate_limit),
  OldHttp = child_pid(?HTTP),
  exit(child_pid(chat_pg), kill),
  _ = wait_new(chat_rate_limit, OldRate),   %% later siblings restart together
  _ = wait_new(?HTTP, OldHttp).

bad_config_fails_fast(_) ->
  application:stop(chat),
  os:putenv("CHAT_HTTP_PORT", "not-a-port"),
  {error, {{invalid_config, Problems}, _}} = application:start(chat),
  true = lists:member({"CHAT_HTTP_PORT", invalid}, Problems),
  os:putenv("CHAT_HTTP_PORT", "18181"),
  ok.
