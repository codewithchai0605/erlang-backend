%% @doc Online/offline presence.
%%
%% Design (docs/decisions/0010):
%%   * "Online" means: the user has at least one authenticated WebSocket connection. It is NEVER stored in
%%     PostgreSQL. Only `users.last_seen_at` is persisted, when the last connection goes away.
%%   * This gen_server monitors every connection pid. When a user's LAST connection dies it waits a grace
%%     period (CHAT_PRESENCE_GRACE_MS) before declaring the user offline: a phone that reconnects within a
%%     few seconds (network switch, app resume) therefore causes no offline/online flicker for the user's peers.
%%   * Transitions (not every connection) are announced to the user's peers by short-lived tasks under
%%     chat_task_sup, so this process never blocks on the database or on fan-out.
%%   * The ETS table (owned here, public reads) answers "is X online?" without a message round-trip.
%%   * Crash recovery: the `pg` scope is the source of truth for live connections. On (re)start this process
%%     rebuilds its state from it instead of starting empty, so a presence crash does not make everybody
%%     look offline. It sits LAST in the supervision tree, so restarting it never disturbs connections.
%%
%% Presence announcements are best-effort pushes (never replayed). Clients re-ask with GetPresence after
%% every (re)connect.
-module(chat_presence).
-behaviour(gen_server).
-include("chat.hrl").
-export([start_link/0, connected/2, is_online/1, online_count/0, snapshot/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(TABLE, chat_presence_tab).

%% users :: #{UserId => #{conns := #{Pid => MonRef}, grace := {GraceId, TimerRef} | undefined}}
%% pids  :: #{Pid => UserId}
-record(st, {users = #{}, pids = #{}}).

%% ------------------------------------------------------------------ API
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% @doc A connection authenticated as UserId. A cast: it never blocks the caller and never fails, even
%% while this process is restarting (the rebuild in init/1 then finds the connection in `pg` anyway).
-spec connected(binary(), pid()) -> ok.
connected(UserId, Pid) -> gen_server:cast(?MODULE, {connected, UserId, Pid}).

-spec is_online(binary()) -> boolean().
is_online(UserId) ->
  try ets:member(?TABLE, UserId)
  catch error:badarg -> false      %% table not there (process restarting)
  end.

online_count() ->
  try ets:info(?TABLE, size) of
    N when is_integer(N) -> N;
    _ -> 0
  catch error:badarg -> 0
  end.

%% @doc Presence of the users Requester shares a conversation with. Wanted = [] means all of them; ids that
%% are not peers are silently omitted (a stranger's presence must not be probeable).
-spec snapshot(binary(), [binary()]) -> {ok, [map()]} | {error, term()}.
snapshot(Requester, Wanted) ->
  case chat_repo:peer_ids(Requester) of
    {ok, Peers} ->
      Ids = case Wanted of
              [] -> Peers;
              _ -> [I || I <- lists:usort(Wanted), lists:member(I, Peers)]
            end,
      Offline = [I || I <- Ids, not is_online(I)],
      case chat_repo:get_last_seen(Offline) of
        {ok, Seen} ->
          {ok, [#{user_id => I, online => is_online(I), last_seen_unix_ms => maps:get(I, Seen, 0)} || I <- Ids]};
        {error, _} -> {error, internal}
      end;
    {error, _} -> {error, internal}
  end.

%% ------------------------------------------------------------------ gen_server
init([]) ->
  process_flag(trap_exit, true),      %% so terminate/2 runs on supervisor shutdown (persist last-seen)
  ets:new(?TABLE, [named_table, protected, set, {read_concurrency, true}]),
  St = lists:foldl(fun({U, Pid}, S) -> add_conn(U, Pid, S, false) end, #st{}, live_connections()),
  {ok, St}.

handle_call(_Req, _From, St) -> {reply, ok, St}.

handle_cast({connected, U, Pid}, St) -> {noreply, add_conn(U, Pid, St, true)};
handle_cast(_Msg, St) -> {noreply, St}.

handle_info({'DOWN', Ref, process, Pid, _Reason}, #st{pids = Pids} = St) ->
  case Pids of
    #{Pid := U} -> {noreply, drop_conn(U, Pid, Ref, St)};
    _ -> {noreply, St}
  end;
handle_info({grace_over, U, Id}, #st{users = Users} = St) ->
  case Users of
    #{U := #{conns := Conns, grace := {Id, _Timer}}} when map_size(Conns) =:= 0 ->
      {noreply, go_offline(U, St)};
    _ -> {noreply, St}               %% stale timer: the user reconnected (or was already handled)
  end;
handle_info(_Info, St) -> {noreply, St}.

%% Orderly shutdown: connections are closing, so the grace timers will never fire. Record "last seen now"
%% for everyone still marked online, in ONE statement.
terminate(_Reason, #st{users = Users}) ->
  Online = [U || {U, _} <- maps:to_list(Users), ets:member(?TABLE, U)],
  _ = chat_repo:touch_last_seen(Online, erlang:system_time(millisecond)),
  ok.

%% ------------------------------------------------------------------ state transitions
add_conn(U, Pid, #st{users = Users, pids = Pids} = St, Announce) ->
  case Pids of
    #{Pid := _} -> St;                                   %% duplicate notification
    _ ->
      Ref = erlang:monitor(process, Pid),
      Entry0 = maps:get(U, Users, #{conns => #{}, grace => undefined}),
      #{conns := Conns, grace := Grace} = Entry0,
      cancel(Grace),
      WasOnline = ets:member(?TABLE, U),
      Entry = #{conns => Conns#{Pid => Ref}, grace => undefined},
      St1 = St#st{users = Users#{U => Entry}, pids = Pids#{Pid => U}},
      case WasOnline of
        true -> ok;                                      %% reconnect inside the grace window, or a 2nd device
        false ->
          ets:insert(?TABLE, {U}),
          Announce andalso announce(U, true, 0)
      end,
      St1
  end.

drop_conn(U, Pid, Ref, #st{users = Users, pids = Pids} = St) ->
  erlang:demonitor(Ref, [flush]),
  #{conns := Conns} = Entry = maps:get(U, Users),
  Conns1 = maps:remove(Pid, Conns),
  St1 = St#st{pids = maps:remove(Pid, Pids)},
  case map_size(Conns1) of
    0 ->
      case chat_config:get(presence_grace_ms) of
        0 -> go_offline(U, St1#st{users = Users#{U => Entry#{conns => Conns1}}});
        Ms ->
          Id = make_ref(),
          Timer = erlang:send_after(Ms, self(), {grace_over, U, Id}),
          St1#st{users = Users#{U => Entry#{conns => Conns1, grace => {Id, Timer}}}}
      end;
    _ ->
      St1#st{users = Users#{U => Entry#{conns => Conns1}}}
  end.

go_offline(U, #st{users = Users} = St) ->
  ets:delete(?TABLE, U),
  announce(U, false, erlang:system_time(millisecond)),
  St#st{users = maps:remove(U, Users)}.

%% cancel_timer/1 stops a timer that has not fired. If it already fired, its message may be in the mailbox:
%% handle_info/2 then ignores it, because the stored grace id no longer matches (stale-timer pattern).
cancel(undefined) -> ok;
cancel({_Id, Timer}) -> _ = erlang:cancel_timer(Timer), ok.

%% Fan out through a supervised task: persist last-seen when going offline, then tell the user's peers.
announce(U, Online, LastSeenMs) ->
  chat_metrics:inc(presence_transitions_total),
  _ = chat_task_sup:run(fun() ->
    Online orelse chat_repo:touch_last_seen([U], LastSeenMs),
    case chat_repo:peer_ids(U) of
      {ok, Peers} ->
        Env = chat_protocol:envelope(<<>>, {presence, #{user_id => U, online => Online, last_seen_unix_ms => LastSeenMs}}),
        chat_dispatch:push(Peers, Env, undefined);
      {error, _} -> ok
    end
  end),
  ok.

live_connections() ->
  try [{U, Pid} || {user, U} = G <- pg:which_groups(?CONN_SCOPE), Pid <- pg:get_local_members(?CONN_SCOPE, G)]
  catch _:_ -> []
  end.
