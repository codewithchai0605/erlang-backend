%% @doc Dynamic supervisor (OTP: simple_one_for_one) for short-lived tasks. Children are `temporary`: a
%% crashed task is logged but never restarted, because re-running a half-done broadcast would be wrong.
%% Overload protection: past ?MAX_TASKS concurrent tasks new ones are DROPPED (counted in metrics). Everything
%% run here is best-effort by design (presence announcements); clients recover through GetPresence on
%% reconnect, so dropping is safer than queueing without bound behind a slow database.
-module(chat_task_sup).
-behaviour(supervisor).
-export([start_link/0, run/1, init/1]).
-define(MAX_TASKS, 500).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec run(fun(() -> term())) -> ok | {error, overloaded}.
run(Fun) ->
  case proplists:get_value(active, supervisor:count_children(?MODULE), 0) of
    N when N >= ?MAX_TASKS ->
      chat_metrics:inc(tasks_dropped_total),
      {error, overloaded};
    _ ->
      case supervisor:start_child(?MODULE, [Fun]) of
        {ok, _Pid} -> ok;
        {error, _} -> {error, overloaded}
      end
  end.

init([]) ->
  {ok, {#{strategy => simple_one_for_one, intensity => 10, period => 10},
        [#{id => chat_task, start => {chat_task, start_link, []}, restart => temporary, shutdown => 1000}]}}.
