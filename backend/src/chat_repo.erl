%% @doc Storage behaviour. Domain modules call chat_repo:Fun(...), which delegates to the configured
%% adapter (chat_repo_pg today). Operations are COARSE-GRAINED and transactional inside the adapter
%% (e.g. insert_message assigns the sequence number and stores the row atomically), so a second adapter
%% (SQLite for local development) only has to implement these callbacks.
-module(chat_repo).

-type id() :: binary().
-type user() :: #{id := id(), username := binary(), display_name := binary()}.
-type message() :: #{id := id(), conversation_id := id(), seq := integer(), sender_id := id(),
                     client_message_id := binary(), text := binary(), created_at_ms := integer()}.
-type member() :: #{user_id := id(), username := binary(), display_name := binary(),
                    delivered_seq := integer(), read_seq := integer(),
                    role := owner | admin | member, from_seq := integer()}.
-type conversation() :: #{id := id(), kind := direct | group, title := binary(), last_seq := integer(),
                          last_activity_ms := integer(), members := [member()]}.
-export_type([id/0, user/0, message/0, member/0, conversation/0]).

-callback ping() -> ok | {error, term()}.
-callback create_user(#{username := binary(), display_name := binary(), password_hash := binary()}) ->
  {ok, user()} | {error, username_taken | term()}.
-callback find_user_by_username(binary()) -> {ok, map()} | not_found | {error, term()}.
-callback get_user(id()) -> {ok, user()} | not_found | {error, term()}.
-callback update_display_name(id(), binary()) -> {ok, user()} | not_found | {error, term()}.
-callback create_device(id(), binary(), binary() | null) -> {ok, id()} | {error, term()}.
-callback create_session(map()) -> {ok, id()} | {error, term()}.
-callback find_session_by_access(binary()) -> {ok, #{id := id(), user_id := id()}} | not_found | {error, term()}.
-callback find_session_by_refresh(binary()) -> {ok, map()} | not_found | {error, term()}.
-callback rotate_session(id(), binary(), binary(), binary(), pos_integer(), pos_integer()) -> ok | {error, stale | term()}.
-callback revoke_session(id()) -> ok | {error, term()}.
-callback revoke_all_sessions(id()) -> {ok, [id()]} | {error, term()}.
-callback create_or_get_direct(id(), id()) -> {ok, id()} | {error, term()}.
-callback get_conversation(id()) -> {ok, conversation()} | not_found | {error, term()}.
-callback list_conversations(id()) -> {ok, [conversation()]} | {error, term()}.
-callback member_ids(id()) -> {ok, [id()]} | {error, term()}.
-callback insert_message(id(), id(), binary(), binary()) -> {ok, message(), new | duplicate} | {error, term()}.
-callback messages_after(id(), integer(), pos_integer()) -> {ok, [message()]} | {error, term()}.
%% messages_before(Conversation, BeforeSeq (0 = newest), MinSeq (exclusive lower bound), Limit)
-callback messages_before(id(), integer(), integer(), pos_integer()) -> {ok, [message()]} | {error, term()}.
-callback advance_receipt(delivered | read, id(), id(), integer()) ->
  {ok, #{delivered_seq := integer(), read_seq := integer()}} | not_member | {error, term()}.

%% Milestone 5: groups, presence persistence.
-callback create_group(Owner :: id(), Title :: binary(), Others :: [id()]) -> {ok, id()} | {error, unknown_user | term()}.
-callback add_members(id(), [id()], MaxMembers :: pos_integer()) ->
  {ok, Added :: [id()]} | {error, not_found | not_a_group | unknown_user | group_full | term()}.
-callback remove_member(id(), id()) ->
  {ok, #{conversation_deleted := boolean()}} | {error, not_found | not_member | term()}.
-callback rename_conversation(id(), binary()) -> ok | not_found | {error, term()}.
-callback peer_ids(id()) -> {ok, [id()]} | {error, term()}.
-callback get_last_seen([id()]) -> {ok, #{id() => integer()}} | {error, term()}.
-callback touch_last_seen([id()], EpochMs :: integer()) -> ok | {error, term()}.

-export([ping/0, create_user/1, find_user_by_username/1, get_user/1, update_display_name/2,
         create_device/3, create_session/1, find_session_by_access/1, find_session_by_refresh/1,
         rotate_session/6, revoke_session/1, revoke_all_sessions/1, create_or_get_direct/2,
         get_conversation/1, list_conversations/1, member_ids/1, insert_message/4,
         messages_after/3, messages_before/4, advance_receipt/4,
         create_group/3, add_members/3, remove_member/2, rename_conversation/2, peer_ids/1,
         get_last_seen/1, touch_last_seen/2]).

adapter() -> chat_repo_pg.

ping() -> (adapter()):ping().
create_user(M) -> (adapter()):create_user(M).
find_user_by_username(U) -> (adapter()):find_user_by_username(U).
get_user(Id) -> (adapter()):get_user(Id).
update_display_name(Id, N) -> (adapter()):update_display_name(Id, N).
create_device(U, P, L) -> (adapter()):create_device(U, P, L).
create_session(M) -> (adapter()):create_session(M).
find_session_by_access(H) -> (adapter()):find_session_by_access(H).
find_session_by_refresh(H) -> (adapter()):find_session_by_refresh(H).
rotate_session(S, O, A, R, AT, RT) -> (adapter()):rotate_session(S, O, A, R, AT, RT).
revoke_session(S) -> (adapter()):revoke_session(S).
revoke_all_sessions(U) -> (adapter()):revoke_all_sessions(U).
create_or_get_direct(A, B) -> (adapter()):create_or_get_direct(A, B).
get_conversation(C) -> (adapter()):get_conversation(C).
list_conversations(U) -> (adapter()):list_conversations(U).
member_ids(C) -> (adapter()):member_ids(C).
insert_message(C, S, M, T) -> (adapter()):insert_message(C, S, M, T).
messages_after(C, S, L) -> (adapter()):messages_after(C, S, L).
messages_before(C, S, Min, L) -> (adapter()):messages_before(C, S, Min, L).
advance_receipt(K, C, U, S) -> (adapter()):advance_receipt(K, C, U, S).
create_group(O, T, M) -> (adapter()):create_group(O, T, M).
add_members(C, U, Max) -> (adapter()):add_members(C, U, Max).
remove_member(C, U) -> (adapter()):remove_member(C, U).
rename_conversation(C, T) -> (adapter()):rename_conversation(C, T).
peer_ids(U) -> (adapter()):peer_ids(U).
get_last_seen(Ids) -> (adapter()):get_last_seen(Ids).
touch_last_seen(Ids, Ms) -> (adapter()):touch_last_seen(Ids, Ms).
