%% End-to-end tests against a REAL PostgreSQL. Skipped unless CHAT_TEST_DB_NAME/USER/PASSWORD are set.
%% Optional: CHAT_TEST_DB_HOST (default 127.0.0.1) and CHAT_TEST_DB_SSL=disable|require|verify (default disable).
%% The database should be disposable: tests create users with random names and leave them behind.
-module(chat_e2e_SUITE).
-include_lib("common_test/include/ct.hrl").
-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([auth_flow/1, refresh_reuse_revokes_session/1, ws_requires_hello/1, ws_rejects_text_frames/1,
         ws_rejects_bad_token/1, chat_flow/1, non_member_is_denied/1,
         typing_relay/1, presence_flow/1, concurrent_duplicate_sends/1, group_flow/1, group_limits/1, direct_chats_are_not_groups/1]).
-define(PORT, 18182).

all() -> [auth_flow, refresh_reuse_revokes_session, ws_requires_hello, ws_rejects_text_frames,
          ws_rejects_bad_token, chat_flow, non_member_is_denied,
          typing_relay, presence_flow, concurrent_duplicate_sends, group_flow, group_limits, direct_chats_are_not_groups].

init_per_suite(Config) ->
  case {os:getenv("CHAT_TEST_DB_NAME"), os:getenv("CHAT_TEST_DB_USER"), os:getenv("CHAT_TEST_DB_PASSWORD")} of
    {N, U, P} when is_list(N), is_list(U), is_list(P) ->
      [os:putenv(K, V) || {K, V} <- [{"CHAT_DB_NAME", N}, {"CHAT_DB_USER", U}, {"CHAT_DB_PASSWORD", P},
                                     {"CHAT_DB_HOST", os:getenv("CHAT_TEST_DB_HOST", "127.0.0.1")},
                                     {"CHAT_DB_SSL", os:getenv("CHAT_TEST_DB_SSL", "disable")},
                                     {"CHAT_RUN_MIGRATIONS", "true"}, {"CHAT_HTTP_PORT", integer_to_list(?PORT)},
                                     {"CHAT_PRESENCE_GRACE_MS", "400"}, {"CHAT_RATE_AUTH_PER_MINUTE", "10000"}, {"CHAT_MAX_GROUP_MEMBERS", "4"}]],
      {ok, _} = application:ensure_all_started(chat),
      {ok, _} = application:ensure_all_started(inets),
      {ok, _} = application:ensure_all_started(gun),
      Config;
    _ -> {skip, "set CHAT_TEST_DB_NAME, CHAT_TEST_DB_USER and CHAT_TEST_DB_PASSWORD to run"}
  end.

end_per_suite(_) -> application:stop(chat), ok.

%% ------------------------------------------------------------------ HTTP helpers
post(Path, Map) -> post(Path, Map, []).
post(Path, Map, Headers) ->
  Url = "http://127.0.0.1:" ++ integer_to_list(?PORT) ++ Path,
  Body = iolist_to_binary(json:encode(Map)),
  {ok, {{_, Status, _}, _, Resp}} =
    httpc:request(post, {Url, Headers, "application/json", Body}, [], [{body_format, binary}]),
  {Status, case Resp of <<>> -> #{}; _ -> json:decode(Resp) end}.

username() -> iolist_to_binary(["u", binary:encode_hex(crypto:strong_rand_bytes(5), lowercase)]).

register_user() ->
  Name = username(),
  {201, #{<<"user">> := #{<<"id">> := Id}, <<"tokens">> := T}} =
    post("/api/v1/auth/register", #{username => Name, password => <<"correct horse">>, display_name => Name}),
  #{id => Id, name => Name, access => maps:get(<<"access_token">>, T), refresh => maps:get(<<"refresh_token">>, T)}.

%% ------------------------------------------------------------------ WebSocket helpers
ws_open() ->
  {ok, Conn} = gun:open("127.0.0.1", ?PORT, #{protocols => [http]}),
  {ok, _} = gun:await_up(Conn),
  Ref = gun:ws_upgrade(Conn, "/ws"),
  receive {gun_upgrade, Conn, Ref, [<<"websocket">>], _} -> {Conn, Ref}
  after 5000 -> ct:fail(ws_upgrade_timeout) end.

ws_send({Conn, Ref}, ReqId, Body) ->
  Bin = iolist_to_binary(chat_pb:encode_msg(#{request_id => ReqId, body => Body}, 'ClientEnvelope')),
  gun:ws_send(Conn, Ref, {binary, Bin}).

%% Presence pushes can arrive at any time; most tests are about something else, so by default they are skipped
%% (exactly what a real client does: presence is a side channel). Presence tests use ws_recv_any/1.
ws_recv(Ws) -> ws_recv(Ws, 5000).
ws_recv(Ws, Timeout) ->
  case ws_recv_raw(Ws, Timeout) of
    #{body := {presence, _}} -> ws_recv(Ws, Timeout);
    Other -> Other
  end.
ws_recv_any(Ws) -> ws_recv_raw(Ws, 5000).

ws_recv_raw({Conn, _}, Timeout) ->
  receive
    {gun_ws, Conn, _, {binary, Bin}} -> chat_pb:decode_msg(Bin, 'ServerEnvelope');
    {gun_ws, Conn, _, {close, Code, _}} -> {closed, Code};
    {gun_ws, Conn, _, close} -> {closed, 1005}
  after Timeout -> timeout
  end.

ws_login(User) ->
  Ws = ws_open(),
  ws_send(Ws, <<"h">>, {hello, #{protocol_version => 1, access_token => maps:get(access, User)}}),
  #{body := {hello_ack, #{user_id := Id}}} = ws_recv(Ws),
  Id = maps:get(id, User),
  Ws.

%% ------------------------------------------------------------------ cases
auth_flow(_) ->
  U = register_user(),
  Name = maps:get(name, U),
  {409, _} = post("/api/v1/auth/register", #{username => Name, password => <<"correct horse">>, display_name => <<"x">>}),
  {401, _} = post("/api/v1/auth/login", #{username => Name, password => <<"wrong password">>}),
  {200, #{<<"tokens">> := T}} = post("/api/v1/auth/login", #{username => Name, password => <<"correct horse">>}),
  {200, #{<<"tokens">> := T2}} = post("/api/v1/auth/refresh", #{refresh_token => maps:get(<<"refresh_token">>, T)}),
  true = maps:get(<<"refresh_token">>, T2) =/= maps:get(<<"refresh_token">>, T),
  {400, _} = post("/api/v1/auth/register", #{username => <<"x">>, password => <<"short">>, display_name => <<"">>}).

refresh_reuse_revokes_session(_) ->
  U = register_user(),
  Old = maps:get(refresh, U),
  {200, #{<<"tokens">> := #{<<"refresh_token">> := New}}} = post("/api/v1/auth/refresh", #{refresh_token => Old}),
  {401, _} = post("/api/v1/auth/refresh", #{refresh_token => Old}),      %% reuse detected
  {401, _} = post("/api/v1/auth/refresh", #{refresh_token => New}).      %% whole session revoked

ws_requires_hello(_) ->
  Ws = ws_open(),
  ws_send(Ws, <<"1">>, {list_conversations, #{}}),
  #{body := {error, #{code := 'ERROR_CODE_UNAUTHENTICATED'}}} = ws_recv(Ws),
  {closed, 1008} = ws_recv(Ws).

ws_rejects_text_frames(_) ->
  {Conn, Ref} = Ws = ws_open(),
  gun:ws_send(Conn, Ref, {text, <<"{\"json\":true}">>}),
  {closed, 1003} = ws_recv(Ws).

ws_rejects_bad_token(_) ->
  Ws = ws_open(),
  ws_send(Ws, <<"h">>, {hello, #{protocol_version => 1, access_token => <<"nope">>}}),
  #{body := {error, #{code := 'ERROR_CODE_UNAUTHENTICATED'}}} = ws_recv(Ws),
  {closed, 1008} = ws_recv(Ws).

chat_flow(_) ->
  A = register_user(), B = register_user(),
  WsA = ws_login(A), WsB = ws_login(B),
  ws_send(WsA, <<"c">>, {create_direct, #{peer_user_id => maps:get(id, B)}}),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsA),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsB),         %% pushed to the peer

  Send = fun(Ws, Cm, Text) -> ws_send(Ws, Cm, {send_message, #{conversation_id => Conv, client_message_id => Cm, text => Text}}) end,
  Send(WsA, <<"m1">>, <<"hello">>),
  #{body := {accepted, #{seq := 1, message_id := MsgId, duplicate := false}}} = ws_recv(WsA),
  #{body := {new_message, #{seq := 1, text := <<"hello">>, sender_id := SenderA}}} = ws_recv(WsB),
  SenderA = maps:get(id, A),

  %% idempotent retry: same client_message_id -> same message, flagged duplicate, nothing re-pushed
  Send(WsA, <<"m1">>, <<"hello">>),
  #{body := {accepted, #{seq := 1, message_id := MsgId, duplicate := true}}} = ws_recv(WsA),

  %% delivery receipt flows back to the sender
  ws_send(WsB, <<"d">>, {ack_delivered, #{conversation_id => Conv, delivered_up_to_seq => 1}}),
  #{body := {receipt, #{delivered_up_to_seq := 1}}} = ws_recv(WsB),
  #{body := {receipt, #{user_id := UserB, delivered_up_to_seq := 1}}} = ws_recv(WsA),
  UserB = maps:get(id, B),

  %% B goes offline; A sends two more; B reconnects and syncs from its cursor
  {ConnB, _} = WsB, gun:close(ConnB),
  Send(WsA, <<"m2">>, <<"two">>), #{body := {accepted, #{seq := 2}}} = ws_recv(WsA),
  Send(WsA, <<"m3">>, <<"three">>), #{body := {accepted, #{seq := 3}}} = ws_recv(WsA),
  WsB2 = ws_login(B),
  ws_send(WsB2, <<"s">>, {sync_request, #{conversation_id => Conv, after_seq => 1, limit => 10}}),
  #{body := {batch, #{messages := [#{seq := 2}, #{seq := 3}], has_more := false}}} = ws_recv(WsB2),

  %% backward history, paged
  ws_send(WsB2, <<"hi">>, {history_request, #{conversation_id => Conv, before_seq => 0, limit => 2}}),
  #{body := {batch, #{messages := [#{seq := 2}, #{seq := 3}], has_more := true}}} = ws_recv(WsB2).

non_member_is_denied(_) ->
  A = register_user(), B = register_user(), C = register_user(),
  WsA = ws_login(A), WsC = ws_login(C),
  ws_send(WsA, <<"c">>, {create_direct, #{peer_user_id => maps:get(id, B)}}),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsA),
  ws_send(WsC, <<"s">>, {sync_request, #{conversation_id => Conv, after_seq => 0, limit => 10}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC),
  ws_send(WsC, <<"m">>, {send_message, #{conversation_id => Conv, client_message_id => <<"x1">>, text => <<"intruder">>}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC).

%% ------------------------------------------------------------------ Milestone 5
id(U) -> maps:get(id, U).

direct(WsA, WsB, B) ->
  ws_send(WsA, <<"d">>, {create_direct, #{peer_user_id => id(B)}}),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsA),
  #{body := {conversation, #{conversation_id := Conv}}} = ws_recv(WsB),
  Conv.

typing_relay(_) ->
  A = register_user(), B = register_user(), C = register_user(),
  WsA = ws_login(A), WsB = ws_login(B), WsC = ws_login(C),
  Conv = direct(WsA, WsB, B),
  UA = id(A),
  ws_send(WsA, <<>>, {typing, #{conversation_id => Conv, is_typing => true}}),
  #{request_id := <<>>, body := {typing, #{conversation_id := Conv, user_id := UA, is_typing := true}}} = ws_recv(WsB),
  %% fire-and-forget: the sender gets neither an echo nor a reply, so the next frame answers the next request
  ws_send(WsA, <<"l">>, {list_conversations, #{}}),
  #{request_id := <<"l">>, body := {conversation_list, _}} = ws_recv(WsA),
  ws_send(WsA, <<>>, {typing, #{conversation_id => Conv, is_typing => false}}),
  #{body := {typing, #{is_typing := false}}} = ws_recv(WsB),
  %% a non-member cannot type into someone else's chat, and nobody is told about the attempt
  ws_send(WsC, <<"t">>, {typing, #{conversation_id => Conv, is_typing => true}}),
  #{request_id := <<"t">>, body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC),
  timeout = ws_recv(WsB, 300).

presence_flow(_) ->
  A = register_user(), B = register_user(), C = register_user(),
  WsA = ws_login(A), WsB = ws_login(B), WsC = ws_login(C),
  UB = id(B),
  _Conv = direct(WsA, WsB, B),
  ws_send(WsA, <<"p">>, {get_presence, #{user_ids => []}}),
  #{body := {presence_snapshot, #{users := [#{user_id := UB, online := true, last_seen_unix_ms := 0}]}}} = ws_recv(WsA),
  %% a stranger cannot probe B's presence
  ws_send(WsC, <<"p">>, {get_presence, #{user_ids => [UB]}}),
  #{body := {presence_snapshot, #{users := []}}} = ws_recv(WsC),

  %% a drop that heals inside the grace period causes NO offline/online flicker for peers
  {ConnB, _} = WsB, gun:close(ConnB),
  WsB2 = ws_login(B),
  timeout = ws_recv_any_for(WsA, 900),

  %% a real departure is announced after the grace period, with a last-seen time that is also persisted
  {ConnB2, _} = WsB2, gun:close(ConnB2),
  #{body := {presence, #{user_id := UB, online := false, last_seen_unix_ms := Seen}}} = ws_recv_any(WsA),
  true = Seen > 0,
  ws_send(WsA, <<"p2">>, {get_presence, #{user_ids => []}}),
  #{body := {presence_snapshot, #{users := [#{user_id := UB, online := false, last_seen_unix_ms := Seen2}]}}} = ws_recv(WsA),
  true = Seen2 > 0,

  %% and coming back is announced immediately
  _WsB3 = ws_login(B),
  #{body := {presence, #{user_id := UB, online := true}}} = ws_recv_any(WsA).

ws_recv_any_for(Ws, Ms) -> ws_recv_raw(Ws, Ms).

group_flow(_) ->
  [A, B, C, D] = [register_user() || _ <- lists:seq(1, 4)],
  [WsA, WsB, WsC, WsD] = [ws_login(U) || U <- [A, B, C, D]],
  [UA, UB, UC, UD] = [id(U) || U <- [A, B, C, D]],
  Send = fun(Ws, Conv, Cm, Text) -> ws_send(Ws, Cm, {send_message, #{conversation_id => Conv, client_message_id => Cm, text => Text}}) end,

  %% creation errors: nobody to chat with / unknown user
  ws_send(WsA, <<"g0">>, {create_group, #{title => <<"Solo">>, member_user_ids => []}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT'}}} = ws_recv(WsA),
  ws_send(WsA, <<"g0b">>, {create_group, #{title => <<"Ghost">>, member_user_ids => [<<"00000000-0000-4000-8000-000000000001">>]}}),
  #{body := {error, #{code := 'ERROR_CODE_NOT_FOUND'}}} = ws_recv(WsA),

  %% A creates a group with B and C and becomes its owner; everyone is told
  ws_send(WsA, <<"g1">>, {create_group, #{title => <<"Team">>, member_user_ids => [UB, UC]}}),
  #{request_id := <<"g1">>, body := {conversation, #{conversation_id := G, kind := 'CONVERSATION_KIND_GROUP',
                                                     title := <<"Team">>, members := Ms}}} = ws_recv(WsA),
  3 = length(Ms),
  ['MEMBER_ROLE_OWNER'] = [R || #{user_id := U, role := R} <- Ms, U =:= UA],
  #{request_id := <<>>, body := {conversation, #{conversation_id := G}}} = ws_recv(WsB),
  #{body := {conversation, #{conversation_id := G}}} = ws_recv(WsC),

  %% messages fan out to every member
  Send(WsA, G, <<"m1">>, <<"hello team">>),
  #{body := {accepted, #{seq := 1}}} = ws_recv(WsA),
  #{body := {new_message, #{seq := 1, text := <<"hello team">>}}} = ws_recv(WsB),
  #{body := {new_message, #{seq := 1}}} = ws_recv(WsC),

  %% only the owner manages membership and the title
  ws_send(WsB, <<"x1">>, {add_members, #{conversation_id => G, user_ids => [UD]}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsB),
  ws_send(WsB, <<"x2">>, {rename_group, #{conversation_id => G, title => <<"Hijack">>}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsB),
  ws_send(WsB, <<"x3">>, {remove_member, #{conversation_id => G, user_id => UC}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsB),

  %% A adds D. D must NOT see what was said before joining (history_from_seq)
  ws_send(WsA, <<"a1">>, {add_members, #{conversation_id => G, user_ids => [UD]}}),
  #{body := {conversation, #{members := Ms4}}} = ws_recv(WsA),
  4 = length(Ms4),
  [#{body := {conversation, #{conversation_id := G}}} = ws_recv(W) || W <- [WsB, WsC, WsD]],
  ws_send(WsD, <<"s0">>, {sync_request, #{conversation_id => G, after_seq => 0, limit => 10}}),
  #{body := {batch, #{messages := [], has_more := false}}} = ws_recv(WsD),
  Send(WsA, G, <<"m2">>, <<"welcome D">>),
  #{body := {accepted, #{seq := 2}}} = ws_recv(WsA),
  #{body := {new_message, #{seq := 2}}} = ws_recv(WsB),
  #{body := {new_message, #{seq := 2}}} = ws_recv(WsC),
  #{body := {new_message, #{seq := 2}}} = ws_recv(WsD),
  ws_send(WsD, <<"h0">>, {history_request, #{conversation_id => G, before_seq => 0, limit => 10}}),
  #{body := {batch, #{messages := [#{seq := 2}], has_more := false}}} = ws_recv(WsD),

  %% rename by the owner reaches everybody
  ws_send(WsA, <<"r1">>, {rename_group, #{conversation_id => G, title => <<"Team 2">>}}),
  #{body := {conversation, #{title := <<"Team 2">>}}} = ws_recv(WsA),
  [#{body := {conversation, #{title := <<"Team 2">>}}} = ws_recv(W) || W <- [WsB, WsC, WsD]],

  %% removing C: C is told to drop the chat and loses all access; the others see the new member list
  ws_send(WsA, <<"self">>, {remove_member, #{conversation_id => G, user_id => UA}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT'}}} = ws_recv(WsA),   %% owners leave, they are not removed
  ws_send(WsA, <<"rm">>, {remove_member, #{conversation_id => G, user_id => UC}}),
  #{body := {conversation, #{members := Ms3}}} = ws_recv(WsA),
  3 = length(Ms3),
  #{body := {conversation_removed, #{conversation_id := G}}} = ws_recv(WsC),
  [#{body := {conversation, #{conversation_id := G}}} = ws_recv(W) || W <- [WsB, WsD]],
  ws_send(WsC, <<"cs">>, {sync_request, #{conversation_id => G, after_seq => 0, limit => 10}}),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC),
  Send(WsC, G, <<"cm">>, <<"still here?">>),
  #{body := {error, #{code := 'ERROR_CODE_PERMISSION_DENIED'}}} = ws_recv(WsC),

  %% the owner leaves: ownership passes to the longest-standing member (B); A is told the chat is gone
  ws_send(WsA, <<"lv">>, {leave_conversation, #{conversation_id => G}}),
  #{request_id := <<"lv">>, body := {conversation_removed, #{conversation_id := G}}} = ws_recv(WsA),
  #{body := {conversation, #{members := MsB}}} = ws_recv(WsB),
  ['MEMBER_ROLE_OWNER'] = [R || #{user_id := U, role := R} <- MsB, U =:= UB],
  2 = length(MsB),
  #{body := {conversation, _}} = ws_recv(WsD),

  %% the last members leave: the conversation disappears
  ws_send(WsB, <<"lvb">>, {leave_conversation, #{conversation_id => G}}),
  #{body := {conversation_removed, _}} = ws_recv(WsB),
  #{body := {conversation, #{members := [_]}}} = ws_recv(WsD),
  ws_send(WsD, <<"lvd">>, {leave_conversation, #{conversation_id => G}}),
  #{body := {conversation_removed, _}} = ws_recv(WsD),
  ws_send(WsD, <<"ls">>, {list_conversations, #{}}),
  #{body := {conversation_list, #{conversations := []}}} = ws_recv(WsD).

group_limits(_) ->
  [A, B, C, D, E] = Us = [register_user() || _ <- lists:seq(1, 5)],
  [WsA | _] = [ws_login(U) || U <- Us],
  Ids = [id(U) || U <- [B, C, D, E]],
  %% CHAT_MAX_GROUP_MEMBERS=4 in this suite: creator + 4 = 5 is too many
  ws_send(WsA, <<"big">>, {create_group, #{title => <<"Big">>, member_user_ids => Ids}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT', message := <<"group is full">>}}} = ws_recv(WsA),
  ws_send(WsA, <<"ok">>, {create_group, #{title => <<"Four">>, member_user_ids => [id(B), id(C), id(D)]}}),
  #{body := {conversation, #{conversation_id := G}}} = ws_recv(WsA),
  ws_send(WsA, <<"add">>, {add_members, #{conversation_id => G, user_ids => [id(E)]}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT', message := <<"group is full">>}}} = ws_recv(WsA),
  _ = A, ok.

direct_chats_are_not_groups(_) ->
  A = register_user(), B = register_user(), C = register_user(),
  WsA = ws_login(A), WsB = ws_login(B), _ = ws_login(C),
  Conv = direct(WsA, WsB, B),
  ws_send(WsA, <<"1">>, {add_members, #{conversation_id => Conv, user_ids => [id(C)]}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT'}}} = ws_recv(WsA),
  ws_send(WsA, <<"2">>, {rename_group, #{conversation_id => Conv, title => <<"x">>}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT'}}} = ws_recv(WsA),
  ws_send(WsA, <<"3">>, {leave_conversation, #{conversation_id => Conv}}),
  #{body := {error, #{code := 'ERROR_CODE_INVALID_ARGUMENT'}}} = ws_recv(WsA).

%% Regression: N sockets of the SAME user send the SAME client_message_id at the same instant. Some lose the
%% race to the unique index (the "conflict" path in chat_repo_pg:insert_message/4). Every request must still be
%% answered with the one stored message; exactly one is "new", the rest "duplicate"; the sequence has no gap.
concurrent_duplicate_sends(_) ->
  A = register_user(), B = register_user(),
  WsA = ws_login(A), WsB = ws_login(B),
  Conv = direct(WsA, WsB, B),
  Sockets = [ws_login(A) || _ <- lists:seq(1, 8)],
  [ws_send(Ws, <<"r">>, {send_message, #{conversation_id => Conv, client_message_id => <<"same-id">>, text => <<"once">>}})
   || Ws <- Sockets],
  Replies = [ws_recv_reply(Ws, <<"r">>) || Ws <- Sockets],
  Accepted = [Acc || #{body := {accepted, Acc}} <- Replies],
  8 = length(Accepted),
  [#{message_id := MsgId, seq := 1}] = lists:usort([maps:with([message_id, seq], X) || X <- Accepted]),
  _ = MsgId,
  1 = length([x || #{duplicate := false} <- Accepted]),
  %% the next distinct message gets seq 2: the aborted attempts left no hole behind
  ws_send(WsA, <<"n">>, {send_message, #{conversation_id => Conv, client_message_id => <<"next">>, text => <<"two">>}}),
  #{body := {accepted, #{seq := 2}}} = ws_recv_reply(WsA, <<"n">>).

%% The reply to a request, skipping server pushes (which have an empty request_id and may arrive first).
ws_recv_reply(Ws, ReqId) ->
  case ws_recv(Ws) of
    #{request_id := ReqId} = Reply -> Reply;
    #{request_id := <<>>} -> ws_recv_reply(Ws, ReqId);
    Other -> ct:fail({unexpected, Other})
  end.
