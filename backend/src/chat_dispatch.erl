%% @doc Delivery of server pushes to LIVE connections. Connections register in the OTP `pg` scope under
%% {user, UserId}; `pg` monitors members, so dead connections disappear automatically (no cleanup code).
%% Pushes are encoded ONCE and sent as a pre-encoded binary to every recipient pid.
-module(chat_dispatch).
-include("chat.hrl").
-export([join/1, push/3, revoke_session/2, close_all/0, connection_count/0]).

join(UserId) -> pg:join(?CONN_SCOPE, {user, UserId}, self()).

%% @doc push(UserIds, ServerEnvelopeMap, ExceptPid) -> ok
push(UserIds, Envelope, ExceptPid) ->
  Bin = chat_protocol:encode_server(Envelope),
  _ = [send(Pid, Bin) || U <- lists:usort(UserIds), Pid <- pg:get_members(?CONN_SCOPE, {user, U}), Pid =/= ExceptPid],
  ok.

%% Backpressure: a slow consumer's mailbox would grow without bound. Past the limit the connection is
%% killed (abruptly: a message could not overtake the backlog); the client reconnects and catches up
%% via sync, because every message is durable before it is ever pushed.
send(Pid, Bin) ->
  Max = chat_config:get(slow_consumer_max_queue),
  case queue_len(Pid) of
    N when N > Max ->
      chat_metrics:inc(slow_consumers_dropped_total),
      ?LOG_WARNING(#{event => slow_consumer_dropped, queue_len => N}),
      exit(Pid, kill);
    _ ->
      Pid ! {push, Bin}
  end.

queue_len(Pid) when node(Pid) =:= node() ->
  case erlang:process_info(Pid, message_queue_len) of
    {message_queue_len, N} -> N;
    undefined -> 0
  end;
queue_len(_) -> 0.

%% @doc Tell a user's connections that a session was revoked; the matching connection closes itself.
revoke_session(UserId, SessionId) ->
  _ = [Pid ! {revoke_session, SessionId} || Pid <- pg:get_members(?CONN_SCOPE, {user, UserId})],
  ok.

%% @doc Graceful shutdown: ask every connection to close with 1001.
close_all() ->
  _ = [Pid ! shutdown_notice || G <- pg:which_groups(?CONN_SCOPE), Pid <- pg:get_local_members(?CONN_SCOPE, G)],
  ok.

connection_count() ->
  lists:sum([length(pg:get_local_members(?CONN_SCOPE, G)) || G <- pg:which_groups(?CONN_SCOPE)]).
