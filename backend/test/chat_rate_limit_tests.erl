-module(chat_rate_limit_tests).
-include_lib("eunit/include/eunit.hrl").

limiter_test_() ->
  {setup,
   fun() -> chat_metrics:init(), {ok, Pid} = chat_rate_limit:start_link(), Pid end,
   fun(Pid) -> unlink(Pid), exit(Pid, shutdown) end,
   fun(_) -> [
     ?_test(begin
       Key = {k, erlang:unique_integer()},
       [?assertEqual(ok, chat_rate_limit:check(t, Key, 3, 600000)) || _ <- [1, 2, 3]],
       ?assertEqual({error, rate_limited}, chat_rate_limit:check(t, Key, 3, 600000))
     end),
     ?_test(begin   %% different keys do not share a budget
       ?assertEqual(ok, chat_rate_limit:check(t, {a, erlang:unique_integer()}, 1, 600000)),
       ?assertEqual(ok, chat_rate_limit:check(t, {b, erlang:unique_integer()}, 1, 600000))
     end)
   ] end}.
