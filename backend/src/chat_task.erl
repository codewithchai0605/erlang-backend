%% @doc A supervised fire-and-forget job. Started only through chat_task_sup:run/1.
%% Used for work that must not block (or crash) a long-lived process: presence fan-out and last-seen writes.
-module(chat_task).
-include("chat.hrl").
-export([start_link/1, run/1]).

start_link(Fun) -> {ok, proc_lib:spawn_link(?MODULE, run, [Fun])}.

run(Fun) ->
  try Fun()
  catch Class:Reason:Stack ->
    ?LOG_ERROR(#{event => task_crashed, class => Class, reason => Reason, stack => Stack}),
    chat_metrics:inc(tasks_failed_total)
  end,
  ok.
