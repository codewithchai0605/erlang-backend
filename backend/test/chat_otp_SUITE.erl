%% Supervision-tree behaviour. Needs NO database: migrations are disabled and the pool connects lazily.
-module(chat_otp_SUITE).
-include_lib("common_test/include/ct.hrl").
-define(HTTP, {ranch_embedded_sup, chat_http}).   %% child id returned by ranch:child_spec/5 (Ranch 2.x embedded supervisor)
-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([tree_starts/1, listener_restarts_alone/1, presence_restart_rebuilds_state/1, presence_grace_period/1,
         task_supervisor_isolates_failures/1, pg_crash_restarts_dependents/1, bad_config_fails_fast/1]).

all() -> [tree_starts, listener_restarts_alone, presence_restart_rebuilds_state, presence_grace_period,
          task_supervisor_isolates_failures, pg_crash_restarts_dependents, bad_config_fails_fast].

init_per_suite(Config) ->
  [os:putenv(K, V) || {K, V} <- [{"CHAT_DB_NAME", "x"}, {"CHAT_DB_USER", "x"}, {"CHAT_DB_PASSWORD", "x"},
                                 {"CHAT_RUN_MIGRATIONS", "false"}, {"CHAT_HTTP_PORT", "18181"},
                                 {"CHAT_PRESENCE_GRACE_MS", "300"}]],
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
  true = is_pid(child_pid(chat_task_sup)),
  true = is_pid(child_pid(chat_presence)),
  {ok, Sock} = gen_tcp:connect("127.0.0.1", 18181, []),
  gen_tcp:close(Sock).

listener_restarts_alone(_) ->
  Pg = child_pid(chat_pg),
  Old = child_pid(?HTTP),
  exit(Old, kill),
  New = wait_new(?HTTP, Old),
  Pg = child_pid(chat_pg),               %% earlier siblings untouched (rest_for_one)
  true = is_pid(New).

%% A fake "connection": joins the pg scope like an authenticated socket and tells presence about itself.
fake_conn(UserId) ->
  Parent = self(),
  Pid = spawn(fun() -> ok = pg:join(chat_conns, {user, UserId}, self()), Parent ! {joined, self()}, receive stop -> ok end end),
  receive {joined, Pid} -> ok after 2000 -> ct:fail(no_join) end,
  chat_presence:connected(UserId, Pid),
  Pid.

wait_until(Fun) -> wait_until(Fun, 60).
wait_until(_, 0) -> ct:fail(condition_not_met);
wait_until(Fun, N) -> case Fun() of true -> ok; false -> timer:sleep(50), wait_until(Fun, N - 1) end.

%% presence is LAST in the tree: crashing it must not touch the listener, and it must rebuild "who is online"
%% from the pg scope (the source of truth) instead of coming back empty.
presence_restart_rebuilds_state(_) ->
  U = <<"u-rebuild">>,
  Conn = fake_conn(U),
  wait_until(fun() -> chat_presence:is_online(U) end),
  Http = child_pid(?HTTP), Old = child_pid(chat_presence),
  exit(Old, kill),
  _ = wait_new(chat_presence, Old),
  Http = child_pid(?HTTP),                                  %% listener (and so every connection) untouched
  wait_until(fun() -> chat_presence:is_online(U) end),      %% rebuilt from pg
  Conn ! stop,
  wait_until(fun() -> not chat_presence:is_online(U) end).  %% and still tracks the connection it re-adopted

%% The grace period: a second connection arriving inside it keeps the user online, no matter that the
%% first one died; only when the LAST connection is gone for the whole grace period do they go offline.
presence_grace_period(_) ->
  U = <<"u-grace">>,
  C1 = fake_conn(U),
  wait_until(fun() -> chat_presence:is_online(U) end),
  C1 ! stop,
  timer:sleep(100),
  true = chat_presence:is_online(U),                        %% inside the 300 ms grace period
  C2 = fake_conn(U),
  timer:sleep(500),
  true = chat_presence:is_online(U),                        %% reconnected: the pending offline was cancelled
  C2 ! stop,
  wait_until(fun() -> not chat_presence:is_online(U) end).

%% simple_one_for_one + temporary children: a crashing task is logged and forgotten; the supervisor and its
%% other tasks are unaffected and nothing is restarted.
task_supervisor_isolates_failures(_) ->
  Parent = self(),
  ok = chat_task_sup:run(fun() -> exit(boom) end),
  ok = chat_task_sup:run(fun() -> erlang:error(badarg) end),
  ok = chat_task_sup:run(fun() -> Parent ! task_ran end),
  receive task_ran -> ok after 2000 -> ct:fail(task_never_ran) end,
  wait_until(fun() -> proplists:get_value(active, supervisor:count_children(chat_task_sup)) =:= 0 end),
  true = is_pid(child_pid(chat_task_sup)).

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
