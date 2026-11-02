%% @doc One WebSocket connection = one Cowboy-owned process running this callback module. No extra
%% per-connection worker is needed: a crash here only kills this connection (process isolation), and the
%% OTP `pg` scope forgets it automatically.
%%
%% Connection lifecycle:  awaiting_hello --(valid Hello)--> ready
%%   * frames must be BINARY protobuf ClientEnvelope; text frames close the socket (1003)
%%   * the first message must be Hello (protocol version + access token); otherwise 1008
%%   * requests are processed one at a time by this process, so a slow database naturally
%%     applies TCP backpressure to a misbehaving sender
-module(chat_ws_handler).
-behaviour(cowboy_websocket).
-include("chat.hrl").
-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2, terminate/3]).

-record(st, {conn_id, peer, phase = awaiting_hello, user_id, session_id, typing_cache = #{}}).

init(Req, _Opts) ->
  case chat_http_handler:origin_allowed(Req) of
    true ->
      Opts = #{max_frame_size => chat_config:get(max_ws_message_bytes),
               idle_timeout => chat_config:get(ws_idle_timeout_ms),
               compress => false},
      St = #st{conn_id = binary:encode_hex(crypto:strong_rand_bytes(6), lowercase),
               peer = chat_http_handler:client_ip(Req)},
      {cowboy_websocket, Req, St, Opts};
    false ->
      {ok, cowboy_req:reply(403, Req), undefined}
  end.

websocket_init(#st{conn_id = Id} = St) ->
  logger:update_process_metadata(#{conn_id => Id}),
  chat_metrics:inc(ws_connections_total),
  erlang:send_after(chat_config:get(hello_timeout_ms), self(), hello_timeout),
  ?LOG_INFO(#{event => ws_connected}),
  {[], St}.

%% ------------------------------------------------------------------ incoming frames
websocket_handle({binary, Bin}, St) -> handle_frame(Bin, St);
websocket_handle({text, _}, St) ->
  chat_metrics:inc(ws_frames_rejected_total),
  {[{close, 1003, <<"binary frames only">>}], St};
websocket_handle(_PingPong, St) -> {[], St}.   %% Cowboy answers pings itself

handle_frame(Bin, St) ->
  case chat_protocol:decode_client(Bin) of
    {error, malformed} ->
      chat_metrics:inc(ws_frames_rejected_total),
      {[err(<<>>, 'ERROR_CODE_INVALID_ARGUMENT', <<"malformed protobuf">>), {close, 1007, <<"malformed">>}], St};
    {ok, ReqId, Body} -> dispatch(ReqId, Body, St)
  end.

dispatch(ReqId, {hello, _} = Body, #st{phase = awaiting_hello} = St) -> hello(ReqId, Body, St);
dispatch(ReqId, _Other, #st{phase = awaiting_hello} = St) ->
  {[err(ReqId, 'ERROR_CODE_UNAUTHENTICATED', <<"hello required">>), {close, 1008, <<"hello required">>}], St};
dispatch(ReqId, Body, #st{phase = ready} = St) ->
  case chat_protocol:validate(Body) of
    {ok, Request} -> run(ReqId, Request, St);
    {error, Code, Msg} -> {[err(ReqId, Code, Msg)], St}
  end.

hello(ReqId, Body, St) ->
  case chat_protocol:validate(Body) of
    {ok, {hello, #{protocol_version := ?PROTOCOL_VERSION, access_token := Token}}} ->
      case chat_rate_limit:check(ws_hello, St#st.peer, chat_config:get(rate_auth_per_min) * 3, 60000) of
        {error, rate_limited} -> reject(ReqId, 'ERROR_CODE_RATE_LIMITED', <<"too many attempts">>, St);
        ok ->
          case chat_auth:authenticate(Token) of
            {ok, #{user_id := U, session_id := S}} ->
              ok = chat_dispatch:join(U),
              chat_presence:connected(U, self()),
              ?LOG_INFO(#{event => ws_authenticated}),
              Ack = #{protocol_version => ?PROTOCOL_VERSION, capabilities => ?CAPABILITIES, user_id => U,
                      server_time_unix_ms => erlang:system_time(millisecond),
                      max_message_bytes => chat_config:get(max_ws_message_bytes),
                      max_text_chars => chat_config:get(max_text_chars)},
              {[reply(ReqId, {hello_ack, Ack})], St#st{phase = ready, user_id = U, session_id = S}};
            _ ->
              chat_metrics:inc(ws_auth_failures_total),
              reject(ReqId, 'ERROR_CODE_UNAUTHENTICATED', <<"invalid or expired access token">>, St)
          end
      end;
    {ok, {hello, _}} -> reject(ReqId, 'ERROR_CODE_UNSUPPORTED_VERSION', <<"unsupported protocol version">>, St);
    {error, Code, Msg} -> reject(ReqId, Code, Msg, St)
  end.

reject(ReqId, Code, Msg, St) -> {[err(ReqId, Code, Msg), {close, 1008, <<"rejected">>}], St}.

%% ------------------------------------------------------------------ authenticated requests
run(ReqId, {hello, _}, St) -> {[err(ReqId, 'ERROR_CODE_INVALID_ARGUMENT', <<"already authenticated">>)], St};
run(ReqId, {send_message, M}, #st{user_id = U} = St) ->
  case chat_messages:send(U, M, self()) of
    {ok, Msg, Status} ->
      #{id := Id, seq := Seq, created_at_ms := Ms, conversation_id := C, client_message_id := Cm} = Msg,
      Acc = #{message_id => Id, client_message_id => Cm, seq => Seq, created_at_unix_ms => Ms,
              duplicate => (Status =:= duplicate), conversation_id => C},
      {[reply(ReqId, {accepted, Acc})], St};
    {error, Reason} -> {[domain_err(ReqId, Reason)], St}
  end;
run(ReqId, {sync_request, #{conversation_id := C, seq := After, limit := L}}, #st{user_id = U} = St) ->
  batch(ReqId, C, chat_messages:sync_after(U, C, After, L), St);
run(ReqId, {history_request, #{conversation_id := C, seq := Before, limit := L}}, #st{user_id = U} = St) ->
  batch(ReqId, C, chat_messages:history_before(U, C, Before, L), St);
run(ReqId, {ack_delivered, #{conversation_id := C, seq := S}}, #st{user_id = U} = St) ->
  receipt(ReqId, chat_delivery:ack_delivered(U, C, S, self()), St);
run(ReqId, {mark_read, #{conversation_id := C, seq := S}}, #st{user_id = U} = St) ->
  receipt(ReqId, chat_delivery:mark_read(U, C, S, self()), St);
run(ReqId, {create_direct, #{peer_user_id := P}}, #st{user_id = U} = St) ->
  case chat_conversations:create_direct(U, P, self()) of
    {ok, Info} -> {[reply(ReqId, {conversation, chat_protocol:conversation_to_pb(Info)})], St};
    {error, Reason} -> {[domain_err(ReqId, Reason)], St}
  end;
run(ReqId, {list_conversations, _}, #st{user_id = U} = St) ->
  case chat_conversations:list(U) of
    {ok, Convs} ->
      List = #{conversations => [chat_protocol:conversation_to_pb(C) || C <- Convs]},
      {[reply(ReqId, {conversation_list, List})], St};
    {error, Reason} -> {[domain_err(ReqId, Reason)], St}
  end;

%% Typing is fire-and-forget: success sends NO reply (the client does not wait for one).
run(ReqId, {typing, #{conversation_id := C, is_typing := T}}, #st{user_id = U, typing_cache = Cache} = St) ->
  case chat_typing:relay(U, C, T, self(), Cache) of
    {ok, Cache1} -> {[], St#st{typing_cache = Cache1}};
    {dropped, Cache1} -> chat_metrics:inc(typing_dropped_total), {[], St#st{typing_cache = Cache1}};
    {error, Reason, Cache1} -> {[domain_err(ReqId, Reason)], St#st{typing_cache = Cache1}}
  end;
run(ReqId, {get_presence, #{user_ids := Ids}}, #st{user_id = U} = St) ->
  case chat_presence:snapshot(U, Ids) of
    {ok, Users} -> {[reply(ReqId, {presence_snapshot, #{users => Users}})], St};
    {error, Reason} -> {[domain_err(ReqId, Reason)], St}
  end;
run(ReqId, {create_group, #{title := T, member_user_ids := Ids}}, #st{user_id = U} = St) ->
  conversation_reply(ReqId, chat_groups:create(U, T, Ids, self()), St);
run(ReqId, {add_members, #{conversation_id := C, user_ids := Ids}}, #st{user_id = U} = St) ->
  conversation_reply(ReqId, chat_groups:add_members(U, C, Ids, self()), St);
run(ReqId, {remove_member, #{conversation_id := C, user_id := Target}}, #st{user_id = U} = St) ->
  conversation_reply(ReqId, chat_groups:remove_member(U, C, Target, self()), St);
run(ReqId, {rename_group, #{conversation_id := C, title := T}}, #st{user_id = U} = St) ->
  conversation_reply(ReqId, chat_groups:rename(U, C, T, self()), St);
run(ReqId, {leave_conversation, #{conversation_id := C}}, #st{user_id = U} = St) ->
  case chat_groups:leave(U, C, self()) of
    ok -> {[reply(ReqId, {conversation_removed, #{conversation_id => C}})], St};
    {error, Reason} -> {[domain_err(ReqId, Reason)], St}
  end.

conversation_reply(ReqId, {ok, Info}, St) ->
  {[reply(ReqId, {conversation, chat_protocol:conversation_to_pb(Info)})], St};
conversation_reply(ReqId, {error, Reason}, St) -> {[domain_err(ReqId, Reason)], St}.

batch(ReqId, Conv, {ok, Msgs, HasMore}, St) ->
  B = #{conversation_id => Conv, messages => [chat_protocol:message_to_pb(M) || M <- Msgs], has_more => HasMore},
  {[reply(ReqId, {batch, B})], St};
batch(ReqId, _Conv, {error, Reason}, St) -> {[domain_err(ReqId, Reason)], St}.

receipt(ReqId, {ok, Update}, St) -> {[reply(ReqId, {receipt, Update})], St};
receipt(ReqId, {error, Reason}, St) -> {[domain_err(ReqId, Reason)], St}.

%% ------------------------------------------------------------------ messages from other processes
websocket_info({push, Bin}, St) -> {[{binary, Bin}], St};
websocket_info(hello_timeout, #st{phase = awaiting_hello} = St) ->
  {[{close, 1008, <<"hello timeout">>}], St};
websocket_info({revoke_session, Sid}, #st{session_id = Sid} = St) ->
  {[{close, 1008, <<"session revoked">>}], St};
websocket_info(shutdown_notice, St) -> {[{close, 1001, <<"server shutting down">>}], St};
websocket_info(_Other, St) -> {[], St}.

terminate(Reason, _Req, #st{phase = Phase}) ->
  ?LOG_INFO(#{event => ws_closed, phase => Phase, reason => short(Reason)}),
  ok;
terminate(_Reason, _Req, _State) -> ok.

short({remote, Code, _}) -> {remote, Code};
short(Other) -> Other.

%% ------------------------------------------------------------------ frame builders
reply(ReqId, Body) -> {binary, chat_protocol:encode_server(chat_protocol:envelope(ReqId, Body))}.
err(ReqId, Code, Msg) -> {binary, chat_protocol:encode_server(chat_protocol:error_envelope(ReqId, Code, Msg))}.
domain_err(ReqId, Reason) -> err(ReqId, chat_protocol:error_code(Reason), error_text(Reason)).

error_text(invalid) -> <<"invalid request">>;
error_text(forbidden) -> <<"not a member of this conversation">>;
error_text(not_found) -> <<"not found">>;
error_text(rate_limited) -> <<"rate limit exceeded">>;
error_text(group_full) -> <<"group is full">>;
error_text(not_a_group) -> <<"only group conversations can be changed">>;
error_text(_) -> <<"internal error">>.
