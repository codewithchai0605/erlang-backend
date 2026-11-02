%% @doc PostgreSQL adapter. All SQL in the system lives here. Conventions: every statement is
%% parameterised ($1, $2 ...; never string-built from input); uuids are selected as text; timestamps are
%% selected as epoch milliseconds (bigint) so no timestamp decoding is needed on the Erlang side.
-module(chat_repo_pg).
-behaviour(chat_repo).
-export([ping/0, create_user/1, find_user_by_username/1, get_user/1, update_display_name/2,
         create_device/3, create_session/1, find_session_by_access/1, find_session_by_refresh/1,
         rotate_session/6, revoke_session/1, revoke_all_sessions/1, create_or_get_direct/2,
         get_conversation/1, list_conversations/1, member_ids/1, insert_message/4,
         messages_after/3, messages_before/4, advance_receipt/4,
         create_group/3, add_members/3, remove_member/2, rename_conversation/2, peer_ids/1,
         get_last_seen/1, touch_last_seen/2]).

-define(MSG_COLS, "id::text, conversation_id::text, seq, sender_id::text, client_message_id, body, "
                  "(extract(epoch from created_at) * 1000)::bigint").
-define(MAX_BIGINT, 9223372036854775807).

ping() -> chat_db:ping().

%% ------------------------------------------------------------------ users
create_user(#{username := U, display_name := D, password_hash := H}) ->
  case chat_db:q("INSERT INTO users (username, display_name, password_hash) VALUES ($1, $2, $3) "
                 "RETURNING id::text, username, display_name", [U, D, H]) of
    {ok, 1, _, [Row]} -> {ok, user(Row)};
    {error, {db, <<"23505">>}} -> {error, username_taken};   %% unique_violation: the only unique key here
    {error, _} = E -> E
  end.

find_user_by_username(U) ->
  case chat_db:q("SELECT id::text, username, display_name, password_hash FROM users WHERE username = $1", [U]) of
    {ok, _, [{Id, Un, Dn, H}]} -> {ok, #{id => Id, username => Un, display_name => Dn, password_hash => H}};
    {ok, _, []} -> not_found;
    {error, _} = E -> E
  end.

get_user(Id) ->
  case chat_db:q("SELECT id::text, username, display_name FROM users WHERE id = $1", [Id]) of
    {ok, _, [Row]} -> {ok, user(Row)};
    {ok, _, []} -> not_found;
    {error, _} = E -> E
  end.

update_display_name(Id, Name) ->
  case chat_db:q("UPDATE users SET display_name = $2, updated_at = now() WHERE id = $1 "
                 "RETURNING id::text, username, display_name", [Id, Name]) of
    {ok, 1, _, [Row]} -> {ok, user(Row)};
    {ok, 0, _, _} -> not_found;
    {error, _} = E -> E
  end.

user({Id, U, D}) -> #{id => Id, username => U, display_name => D}.

%% ------------------------------------------------------------------ devices / sessions
create_device(UserId, Platform, Label) ->
  case chat_db:q("INSERT INTO devices (user_id, platform, label) VALUES ($1, $2, $3) RETURNING id::text",
                 [UserId, Platform, Label]) of
    {ok, 1, _, [{Id}]} -> {ok, Id};
    {error, _} = E -> E
  end.

create_session(#{user_id := U, device_id := Dev, access_hash := AH, access_ttl_s := AT,
                 refresh_hash := RH, refresh_ttl_s := RT}) ->
  case chat_db:q("INSERT INTO sessions (user_id, device_id, access_hash, access_expires_at, refresh_hash, refresh_expires_at) "
                 "VALUES ($1, $2, $3, now() + ($4::int * interval '1 second'), $5, now() + ($6::int * interval '1 second')) "
                 "RETURNING id::text", [U, Dev, AH, AT, RH, RT]) of
    {ok, 1, _, [{Id}]} -> {ok, Id};
    {error, _} = E -> E
  end.

find_session_by_access(Hash) ->
  case chat_db:q("SELECT id::text, user_id::text FROM sessions "
                 "WHERE access_hash = $1 AND revoked_at IS NULL AND access_expires_at > now()", [Hash]) of
    {ok, _, [{Id, U}]} -> {ok, #{id => Id, user_id => U}};
    {ok, _, []} -> not_found;
    {error, _} = E -> E
  end.

find_session_by_refresh(Hash) ->
  case chat_db:q("SELECT id::text, user_id::text, refresh_hash = $1, refresh_expires_at > now() FROM sessions "
                 "WHERE (refresh_hash = $1 OR previous_refresh_hash = $1) AND revoked_at IS NULL LIMIT 1", [Hash]) of
    {ok, _, [{Id, U, IsCurrent, Valid}]} -> {ok, #{id => Id, user_id => U, is_current => IsCurrent, refresh_valid => Valid}};
    {ok, _, []} -> not_found;
    {error, _} = E -> E
  end.

%% Optimistic rotation: only succeeds if the presented refresh hash is still the current one.
rotate_session(Id, OldRefreshHash, NewAccessHash, NewRefreshHash, AccessTtl, RefreshTtl) ->
  case chat_db:q("UPDATE sessions SET previous_refresh_hash = refresh_hash, refresh_hash = $3, "
                 "refresh_expires_at = now() + ($5::int * interval '1 second'), access_hash = $4, "
                 "access_expires_at = now() + ($6::int * interval '1 second'), last_used_at = now() "
                 "WHERE id = $1 AND refresh_hash = $2 AND revoked_at IS NULL",
                 [Id, OldRefreshHash, NewRefreshHash, NewAccessHash, RefreshTtl, AccessTtl]) of
    {ok, 1} -> ok;
    {ok, 0} -> {error, stale};
    {error, _} = E -> E
  end.

revoke_session(Id) ->
  case chat_db:q("UPDATE sessions SET revoked_at = now() WHERE id = $1 AND revoked_at IS NULL", [Id]) of
    {ok, _} -> ok;
    {error, _} = E -> E
  end.

revoke_all_sessions(UserId) ->
  case chat_db:q("UPDATE sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL "
                 "RETURNING id::text", [UserId]) of
    {ok, _, _, Rows} -> {ok, [Id || {Id} <- Rows]};
    {error, _} = E -> E
  end.

%% ------------------------------------------------------------------ conversations
create_or_get_direct(A, B) ->
  Key = direct_key(A, B),
  chat_db:transaction(fun(C) ->
    case chat_db:must(chat_db:equery(C,
           "INSERT INTO conversations (kind, direct_key, created_by) VALUES ('direct', $1, $2) "
           "ON CONFLICT (direct_key) DO NOTHING RETURNING id::text", [Key, A])) of
      {ok, 1, _, [{Id}]} ->
        chat_db:must(chat_db:equery(C,
          "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)", [Id, A, B])),
        {ok, Id};
      {ok, 0, _, []} ->
        {ok, _, [{Id}]} = chat_db:must(chat_db:equery(C,
          "SELECT id::text FROM conversations WHERE direct_key = $1", [Key])),
        {ok, Id}
    end
  end).

direct_key(A, B) when A =< B -> <<A/binary, ":", B/binary>>;
direct_key(A, B) -> <<B/binary, ":", A/binary>>.

-define(CONV_COLS, "c.id::text, c.kind, c.title, c.last_seq, "
                   "(extract(epoch from COALESCE(c.last_message_at, c.created_at)) * 1000)::bigint").
-define(MEMBER_COLS, "m.conversation_id::text, u.id::text, u.username, u.display_name, "
                     "m.last_delivered_seq, m.last_read_seq, m.role, m.history_from_seq").

get_conversation(Id) ->
  case chat_db:q("SELECT " ?CONV_COLS " FROM conversations c WHERE c.id = $1", [Id]) of
    {ok, _, [Row]} ->
      case chat_db:q("SELECT " ?MEMBER_COLS " FROM conversation_members m JOIN users u ON u.id = m.user_id "
                     "WHERE m.conversation_id = $1", [Id]) of
        {ok, _, MRows} -> {ok, hd(attach(([conv(Row)]), MRows))};
        {error, _} = E -> E
      end;
    {ok, _, []} -> not_found;
    {error, _} = E -> E
  end.

list_conversations(UserId) ->
  case chat_db:q("SELECT " ?CONV_COLS " FROM conversations c "
                 "JOIN conversation_members me ON me.conversation_id = c.id AND me.user_id = $1 "
                 "ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC", [UserId]) of
    {ok, _, Rows} ->
      case chat_db:q("SELECT " ?MEMBER_COLS " FROM conversation_members m JOIN users u ON u.id = m.user_id "
                     "WHERE m.conversation_id IN (SELECT conversation_id FROM conversation_members WHERE user_id = $1)",
                     [UserId]) of
        {ok, _, MRows} -> {ok, attach([conv(R) || R <- Rows], MRows)};
        {error, _} = E -> E
      end;
    {error, _} = E -> E
  end.

conv({Id, Kind, Title, LastSeq, ActivityMs}) ->
  #{id => Id, kind => kind(Kind), title => nullable(Title),
    last_seq => LastSeq, last_activity_ms => ActivityMs, members => []}.

kind(<<"direct">>) -> direct;
kind(<<"group">>) -> group.

role(<<"owner">>) -> owner;
role(<<"admin">>) -> admin;
role(<<"member">>) -> member.

nullable(null) -> <<>>;
nullable(V) -> V.

attach(Convs, MemberRows) ->
  ByConv = lists:foldl(fun({CId, UId, Un, Dn, D, R, Role, From}, Acc) ->
             M = #{user_id => UId, username => Un, display_name => Dn, delivered_seq => D, read_seq => R,
                   role => role(Role), from_seq => From},
             maps:update_with(CId, fun(L) -> [M | L] end, [M], Acc)
           end, #{}, MemberRows),
  [C#{members => lists:sort(fun(A, B) -> maps:get(user_id, A) =< maps:get(user_id, B) end,
                            maps:get(maps:get(id, C), ByConv, []))} || C <- Convs].

member_ids(ConvId) ->
  case chat_db:q("SELECT user_id::text FROM conversation_members WHERE conversation_id = $1", [ConvId]) of
    {ok, _, Rows} -> {ok, [U || {U} <- Rows]};
    {error, _} = E -> E
  end.

%% ------------------------------------------------------------------ messages
insert_message(ConvId, SenderId, ClientMsgId, Text) ->
  case chat_db:transaction(fun(C) -> insert_tx(C, ConvId, SenderId, ClientMsgId, Text) end) of
    {error, conflict} ->
      %% lost a race with a concurrent identical send: the other transaction's row is now visible
      case chat_db:with_conn(fun(C) -> select_existing(C, SenderId, ClientMsgId) end) of
        {ok, Msg} -> {ok, Msg, duplicate};
        _ -> {error, conflict}
      end;
    Result -> Result
  end.

insert_tx(C, ConvId, SenderId, ClientMsgId, Text) ->
  case select_existing(C, SenderId, ClientMsgId) of
    {ok, Msg} -> {ok, Msg, duplicate};
    none ->
      %% Row-locks the conversation: concurrent senders are serialised, so seq has no gaps or duplicates.
      {ok, 1, _, [{Seq}]} = chat_db:must(chat_db:equery(C,
        "UPDATE conversations SET last_seq = last_seq + 1, last_message_at = now() WHERE id = $1 "
        "RETURNING last_seq", [ConvId])),
      case chat_db:must(chat_db:equery(C,
             "INSERT INTO messages (conversation_id, seq, sender_id, client_message_id, body) "
             "VALUES ($1, $2, $3, $4, $5) ON CONFLICT (sender_id, client_message_id) DO NOTHING "
             "RETURNING " ?MSG_COLS, [ConvId, Seq, SenderId, ClientMsgId, Text])) of
        {ok, 1, _, [Row]} ->
          %% the sender has trivially "delivered" and "read" their own message
          chat_db:must(chat_db:equery(C,
            "UPDATE conversation_members SET last_delivered_seq = $3, last_read_seq = $3 "
            "WHERE conversation_id = $1 AND user_id = $2", [ConvId, SenderId, Seq])),
          {ok, message(Row), new};
        {ok, 0, _, []} -> throw({abort, conflict})   %% rolls back the seq bump too
      end
  end.

select_existing(C, SenderId, ClientMsgId) ->
  case chat_db:must(chat_db:equery(C, "SELECT " ?MSG_COLS " FROM messages WHERE sender_id = $1 AND client_message_id = $2",
                                   [SenderId, ClientMsgId])) of
    {ok, _, [Row]} -> {ok, message(Row)};
    {ok, _, []} -> none
  end.

messages_after(ConvId, AfterSeq, Limit) ->
  case chat_db:q("SELECT " ?MSG_COLS " FROM messages WHERE conversation_id = $1 AND seq > $2 "
                 "ORDER BY seq ASC LIMIT $3", [ConvId, AfterSeq, Limit]) of
    {ok, _, Rows} -> {ok, [message(R) || R <- Rows]};
    {error, _} = E -> E
  end.

messages_before(ConvId, BeforeSeq, MinSeq, Limit) ->
  Before = case BeforeSeq of 0 -> ?MAX_BIGINT; _ -> BeforeSeq end,
  case chat_db:q("SELECT " ?MSG_COLS " FROM messages WHERE conversation_id = $1 AND seq < $2 AND seq > $3 "
                 "ORDER BY seq DESC LIMIT $4", [ConvId, Before, MinSeq, Limit]) of
    {ok, _, Rows} -> {ok, lists:reverse([message(R) || R <- Rows])};   %% return ascending
    {error, _} = E -> E
  end.

message({Id, Conv, Seq, Sender, CMid, Body, Ms}) ->
  #{id => Id, conversation_id => Conv, seq => Seq, sender_id => Sender, client_message_id => CMid,
    text => Body, created_at_ms => Ms}.

%% ------------------------------------------------------------------ receipts
%% Monotonic (GREATEST) and clamped to the conversation's last_seq so a bogus ack cannot run ahead.
advance_receipt(delivered, ConvId, UserId, Seq) ->
  receipt_result(chat_db:q(
    "UPDATE conversation_members m SET last_delivered_seq = GREATEST(m.last_delivered_seq, LEAST($3::bigint, c.last_seq)) "
    "FROM conversations c WHERE c.id = m.conversation_id AND m.conversation_id = $1 AND m.user_id = $2 "
    "RETURNING m.last_delivered_seq, m.last_read_seq", [ConvId, UserId, Seq]));
advance_receipt(read, ConvId, UserId, Seq) ->
  receipt_result(chat_db:q(
    "UPDATE conversation_members m SET last_read_seq = GREATEST(m.last_read_seq, LEAST($3::bigint, c.last_seq)), "
    "last_delivered_seq = GREATEST(m.last_delivered_seq, LEAST($3::bigint, c.last_seq)) "
    "FROM conversations c WHERE c.id = m.conversation_id AND m.conversation_id = $1 AND m.user_id = $2 "
    "RETURNING m.last_delivered_seq, m.last_read_seq", [ConvId, UserId, Seq])).

receipt_result({ok, 1, _, [{D, R}]}) -> {ok, #{delivered_seq => D, read_seq => R}};
receipt_result({ok, 0, _, _}) -> not_member;
receipt_result({error, _} = E) -> E.

%% ------------------------------------------------------------------ groups (Milestone 5)
%% Membership changes lock the conversation row (SELECT ... FOR UPDATE). Message inserts bump last_seq on
%% the same row, so a member's history_from_seq is read at a well-defined instant: every later message has
%% a larger seq, every earlier one a smaller-or-equal seq.
create_group(Owner, Title, Others) ->
  All = lists:usort([Owner | Others]),
  chat_db:transaction(fun(C) ->
    {ok, _, [{Found}]} = chat_db:must(chat_db:equery(C,
      "SELECT count(*) FROM users WHERE id = ANY($1::uuid[])", [All])),
    case Found =:= length(All) of
      false -> throw({abort, unknown_user});
      true ->
        {ok, 1, _, [{Id}]} = chat_db:must(chat_db:equery(C,
          "INSERT INTO conversations (kind, title, created_by) VALUES ('group', $1, $2) RETURNING id::text",
          [Title, Owner])),
        chat_db:must(chat_db:equery(C,
          "INSERT INTO conversation_members (conversation_id, user_id, role) "
          "SELECT $1::uuid, u, CASE WHEN u = $2::uuid THEN 'owner' ELSE 'member' END FROM unnest($3::uuid[]) AS u",
          [Id, Owner, All])),
        {ok, Id}
    end
  end).

add_members(ConvId, UserIds, MaxMembers) ->
  Wanted = lists:usort(UserIds),
  chat_db:transaction(fun(C) ->
    LastSeq = case chat_db:must(chat_db:equery(C,
        "SELECT kind, last_seq FROM conversations WHERE id = $1 FOR UPDATE", [ConvId])) of
      {ok, _, []} -> throw({abort, not_found});
      {ok, _, [{<<"direct">>, _}]} -> throw({abort, not_a_group});
      {ok, _, [{<<"group">>, L}]} -> L
    end,
    {ok, _, [{Known}]} = chat_db:must(chat_db:equery(C,
      "SELECT count(*) FROM users WHERE id = ANY($1::uuid[])", [Wanted])),
    Known =:= length(Wanted) orelse throw({abort, unknown_user}),
    {ok, _, Existing} = chat_db:must(chat_db:equery(C,
      "SELECT user_id::text FROM conversation_members WHERE conversation_id = $1 AND user_id = ANY($2::uuid[])",
      [ConvId, Wanted])),
    New = Wanted -- [U || {U} <- Existing],
    {ok, _, [{Current}]} = chat_db:must(chat_db:equery(C,
      "SELECT count(*) FROM conversation_members WHERE conversation_id = $1", [ConvId])),
    Current + length(New) =< MaxMembers orelse throw({abort, group_full}),
    New =:= [] orelse chat_db:must(chat_db:equery(C,
      "INSERT INTO conversation_members (conversation_id, user_id, role, history_from_seq, last_delivered_seq, last_read_seq) "
      "SELECT $1::uuid, u, 'member', $3::bigint, $3::bigint, $3::bigint FROM unnest($2::uuid[]) AS u",
      [ConvId, New, LastSeq])),
    {ok, New}
  end).

%% Removes one member. If the owner goes, the longest-standing remaining member becomes owner; if nobody
%% remains the conversation (and, by cascade, its messages) is deleted.
remove_member(ConvId, UserId) ->
  chat_db:transaction(fun(C) ->
    case chat_db:must(chat_db:equery(C, "SELECT 1 FROM conversations WHERE id = $1 FOR UPDATE", [ConvId])) of
      {ok, _, []} -> throw({abort, not_found});
      {ok, _, [_]} -> ok
    end,
    Role = case chat_db:must(chat_db:equery(C,
        "DELETE FROM conversation_members WHERE conversation_id = $1 AND user_id = $2 RETURNING role",
        [ConvId, UserId])) of
      {ok, 0, _, _} -> throw({abort, not_member});
      {ok, 1, _, [{R}]} -> R
    end,
    case chat_db:must(chat_db:equery(C,
        "SELECT user_id::text FROM conversation_members WHERE conversation_id = $1 "
        "ORDER BY joined_at, user_id LIMIT 1", [ConvId])) of
      {ok, _, []} ->
        chat_db:must(chat_db:equery(C, "DELETE FROM conversations WHERE id = $1", [ConvId])),
        {ok, #{conversation_deleted => true}};
      {ok, _, [{Next}]} when Role =:= <<"owner">> ->
        chat_db:must(chat_db:equery(C,
          "UPDATE conversation_members SET role = 'owner' WHERE conversation_id = $1 AND user_id = $2", [ConvId, Next])),
        {ok, #{conversation_deleted => false}};
      {ok, _, [_]} ->
        {ok, #{conversation_deleted => false}}
    end
  end).

rename_conversation(ConvId, Title) ->
  case chat_db:q("UPDATE conversations SET title = $2 WHERE id = $1 AND kind = 'group'", [ConvId, Title]) of
    {ok, 1} -> ok;
    {ok, 0} -> not_found;
    {error, _} = E -> E
  end.

%% ------------------------------------------------------------------ presence support
%% Everyone who shares at least one conversation with User (the audience for presence, and the only users
%% whose presence User may query).
peer_ids(UserId) ->
  case chat_db:q("SELECT DISTINCT m2.user_id::text FROM conversation_members m1 "
                 "JOIN conversation_members m2 ON m2.conversation_id = m1.conversation_id AND m2.user_id <> m1.user_id "
                 "WHERE m1.user_id = $1", [UserId]) of
    {ok, _, Rows} -> {ok, [U || {U} <- Rows]};
    {error, _} = E -> E
  end.

get_last_seen([]) -> {ok, #{}};
get_last_seen(Ids) ->
  case chat_db:q("SELECT id::text, (extract(epoch from last_seen_at) * 1000)::bigint FROM users "
                 "WHERE id = ANY($1::uuid[]) AND last_seen_at IS NOT NULL", [Ids]) of
    {ok, _, Rows} -> {ok, maps:from_list(Rows)};
    {error, _} = E -> E
  end.

touch_last_seen([], _Ms) -> ok;
touch_last_seen(Ids, Ms) ->
  case chat_db:q("UPDATE users SET last_seen_at = to_timestamp($2::bigint / 1000.0) WHERE id = ANY($1::uuid[])", [Ids, Ms]) of
    {ok, _} -> ok;
    {error, _} = E -> E
  end.
