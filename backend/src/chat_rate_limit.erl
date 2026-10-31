%% @doc Fixed-window rate limiter. The ETS table is public (callers update counters directly with
%% ets:update_counter, no message passing), and this process only OWNS the table and sweeps old windows.
-module(chat_rate_limit).
-behaviour(gen_server).
-export([start_link/0, check/4]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).
-define(TABLE, chat_rate_limit_tab).
-define(SWEEP_MS, 60000).

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc check(Name, Key, Limit, WindowMs) -> ok | {error, rate_limited}
check(Name, Key, Limit, WindowMs) ->
  Now = erlang:system_time(millisecond),
  K = {Name, Key, Now div WindowMs},
  Expires = (Now div WindowMs + 2) * WindowMs,
  [Count] = ets:update_counter(?TABLE, K, [{2, 1}], {K, 0, Expires}),
  case Count =< Limit of
    true -> ok;
    false -> chat_metrics:inc(rate_limited_total), {error, rate_limited}
  end.

init([]) ->
  ets:new(?TABLE, [named_table, public, set, {write_concurrency, true}]),
  erlang:send_after(?SWEEP_MS, self(), sweep),
  {ok, #{}}.

handle_call(_Req, _From, S) -> {reply, ok, S}.
handle_cast(_Msg, S) -> {noreply, S}.

handle_info(sweep, S) ->
  Now = erlang:system_time(millisecond),
  ets:select_delete(?TABLE, [{{'_', '_', '$1'}, [{'<', '$1', Now}], [true]}]),
  erlang:send_after(?SWEEP_MS, self(), sweep),
  {noreply, S};
handle_info(_Info, S) -> {noreply, S}.
