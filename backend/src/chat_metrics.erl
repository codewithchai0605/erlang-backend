%% @doc Minimal metrics: a fixed set of `counters` (lock-free, safe from any process) rendered in
%% Prometheus text format. Names are listed once in ?NAMES; the index is the list position.
-module(chat_metrics).
-include("chat.hrl").
-export([init/0, inc/1, inc/2, render/0]).
-define(KEY, {?MODULE, counters}).
-define(GAUGES, []).
-define(NAMES, [http_requests_total, ws_connections_total, ws_auth_failures_total,
                ws_frames_rejected_total, messages_accepted_total, messages_duplicate_total,
                rate_limited_total, slow_consumers_dropped_total]).

init() ->
  case persistent_term:get(?KEY, undefined) of
    undefined -> persistent_term:put(?KEY, counters:new(length(?NAMES), [write_concurrency]));
    _ -> ok
  end.

inc(Name) -> inc(Name, 1).
inc(Name, By) -> counters:add(persistent_term:get(?KEY), idx(Name), By).

idx(Name) -> idx(Name, ?NAMES, 1).
idx(Name, [Name | _], N) -> N;
idx(Name, [_ | T], N) -> idx(Name, T, N + 1).

render() ->
  Ref = persistent_term:get(?KEY),
  Counters = [line(Name, counters:get(Ref, idx(Name))) || Name <- ?NAMES],
  Extra = [line(ws_connections_authenticated, chat_dispatch:connection_count()),
           line(erlang_process_count, erlang:system_info(process_count)),
           line(erlang_memory_total_bytes, erlang:memory(total))] ++ pool_lines(),
  iolist_to_binary(Counters ++ Extra).

line(Name, Val) ->
  IsCounter = lists:member(Name, ?NAMES) andalso not lists:member(Name, ?GAUGES),
  Type = case IsCounter of true -> "counter"; false -> "gauge" end,
  io_lib:format("# TYPE chat_~s ~s~nchat_~s ~w~n", [Name, Type, Name, Val]).

pool_lines() ->
  try poolboy:status(?DB_POOL) of
    {_State, Available, _Overflow, CheckedOut} ->
      [line(db_pool_available, Available), line(db_pool_checked_out, CheckedOut)]
  catch _:_ -> []
  end.
