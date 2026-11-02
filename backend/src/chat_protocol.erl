%% @doc The ONLY module that knows the wire format. Wraps the gpb-generated `chat_pb`, validates decoded
%% requests, and converts domain maps to protobuf maps. gpb (maps option) represents a oneof as
%% `body => {Variant, Value}`.
-module(chat_protocol).
-export([decode_client/1, encode_server/1, validate/1, envelope/2, error_envelope/3,
         message_to_pb/1, conversation_to_pb/1, error_code/1]).

-define(DEFAULT_PAGE, 50).
-define(MAX_PAGE, 100).

%% ------------------------------------------------------------------ codec
-spec decode_client(binary()) -> {ok, binary(), term()} | {error, malformed}.
decode_client(Bin) ->
  try chat_pb:decode_msg(Bin, 'ClientEnvelope') of
    Map when is_map(Map) ->
      Body = case maps:get(body, Map, undefined) of {Tag, Val} -> {Tag, Val}; _ -> none end,
      {ok, maps:get(request_id, Map, <<>>), Body}
  catch _:_ -> {error, malformed}
  end.

-spec encode_server(map()) -> binary().
encode_server(Map) -> iolist_to_binary(chat_pb:encode_msg(Map, 'ServerEnvelope')).

envelope(ReqId, Body) -> #{request_id => ReqId, body => Body}.
error_envelope(ReqId, Code, Msg) -> envelope(ReqId, {error, #{code => Code, message => Msg}}).

%% ------------------------------------------------------------------ validation of decoded requests
-define(INVALID(M), {error, 'ERROR_CODE_INVALID_ARGUMENT', M}).

validate({hello, M}) ->
  case {maps:get(protocol_version, M, 0), chat_validate:token(maps:get(access_token, M, <<>>))} of
    {V, {ok, T}} -> {ok, {hello, #{protocol_version => V, access_token => T}}};
    _ -> ?INVALID(<<"invalid hello">>)
  end;
validate({send_message, M}) ->
  case {chat_validate:uuid(f(conversation_id, M)), chat_validate:client_message_id(f(client_message_id, M)),
        chat_validate:text(f(text, M))} of
    {{ok, C}, {ok, Id}, {ok, T}} ->
      {ok, {send_message, #{conversation_id => C, client_message_id => Id, text => T}}};
    _ -> ?INVALID(<<"invalid send_message">>)
  end;
validate({sync_request, M}) ->
  paged(sync_request, conversation_id, after_seq, M);
validate({history_request, M}) ->
  paged(history_request, conversation_id, before_seq, M);
validate({ack_delivered, M}) ->
  seq_update(ack_delivered, delivered_up_to_seq, M);
validate({mark_read, M}) ->
  seq_update(mark_read, read_up_to_seq, M);
validate({create_direct, M}) ->
  case chat_validate:uuid(f(peer_user_id, M)) of
    {ok, P} -> {ok, {create_direct, #{peer_user_id => P}}};
    _ -> ?INVALID(<<"invalid peer_user_id">>)
  end;
validate({list_conversations, _}) -> {ok, {list_conversations, #{}}};
validate({typing, M}) ->
  case {chat_validate:uuid(f(conversation_id, M)), f(is_typing, M)} of
    {{ok, C}, T} when is_boolean(T) -> {ok, {typing, #{conversation_id => C, is_typing => T}}};
    _ -> ?INVALID(<<"invalid typing event">>)
  end;
validate({create_group, M}) ->
  Max = chat_config:get(max_group_members),
  case {chat_validate:group_title(f(title, M)), chat_validate:uuid_list(maps:get(member_user_ids, M, []), Max)} of
    {{ok, T}, {ok, Ids}} -> {ok, {create_group, #{title => T, member_user_ids => Ids}}};
    _ -> ?INVALID(<<"invalid create_group">>)
  end;
validate({add_members, M}) ->
  Max = chat_config:get(max_group_members),
  case {chat_validate:uuid(f(conversation_id, M)), chat_validate:uuid_list(maps:get(user_ids, M, []), Max)} of
    {{ok, C}, {ok, [_ | _] = Ids}} -> {ok, {add_members, #{conversation_id => C, user_ids => Ids}}};
    _ -> ?INVALID(<<"invalid add_members">>)
  end;
validate({remove_member, M}) ->
  case {chat_validate:uuid(f(conversation_id, M)), chat_validate:uuid(f(user_id, M))} of
    {{ok, C}, {ok, U}} -> {ok, {remove_member, #{conversation_id => C, user_id => U}}};
    _ -> ?INVALID(<<"invalid remove_member">>)
  end;
validate({leave_conversation, M}) ->
  case chat_validate:uuid(f(conversation_id, M)) of
    {ok, C} -> {ok, {leave_conversation, #{conversation_id => C}}};
    _ -> ?INVALID(<<"invalid leave_conversation">>)
  end;
validate({rename_group, M}) ->
  case {chat_validate:uuid(f(conversation_id, M)), chat_validate:group_title(f(title, M))} of
    {{ok, C}, {ok, T}} -> {ok, {rename_group, #{conversation_id => C, title => T}}};
    _ -> ?INVALID(<<"invalid rename_group">>)
  end;
validate({get_presence, M}) ->
  case chat_validate:uuid_list(maps:get(user_ids, M, []), 200) of
    {ok, Ids} -> {ok, {get_presence, #{user_ids => Ids}}};
    _ -> ?INVALID(<<"invalid get_presence">>)
  end;
validate({hello_ack, _}) -> {error, 'ERROR_CODE_UNSUPPORTED_EVENT', <<"unexpected event">>};
validate(none) -> {error, 'ERROR_CODE_UNSUPPORTED_EVENT', <<"empty or unknown event">>};
validate({_, _}) -> {error, 'ERROR_CODE_UNSUPPORTED_EVENT', <<"unknown event">>}.

paged(Tag, ConvKey, SeqKey, M) ->
  Seq = f(SeqKey, M),
  case {chat_validate:uuid(f(ConvKey, M)), is_integer(Seq) andalso Seq >= 0} of
    {{ok, C}, true} ->
      {ok, {Tag, #{conversation_id => C, seq => Seq, limit => clamp(maps:get(limit, M, 0))}}};
    _ -> ?INVALID(<<"invalid request">>)
  end.

seq_update(Tag, SeqKey, M) ->
  Seq = f(SeqKey, M),
  case {chat_validate:uuid(f(conversation_id, M)), is_integer(Seq) andalso Seq >= 0} of
    {{ok, C}, true} -> {ok, {Tag, #{conversation_id => C, seq => Seq}}};
    _ -> ?INVALID(<<"invalid request">>)
  end.

clamp(0) -> ?DEFAULT_PAGE;
clamp(N) when N > ?MAX_PAGE -> ?MAX_PAGE;
clamp(N) -> N.

f(Key, Map) -> maps:get(Key, Map, undefined).

%% ------------------------------------------------------------------ domain -> protobuf
message_to_pb(#{id := Id, conversation_id := C, seq := S, sender_id := Sd, client_message_id := Cm,
                text := T, created_at_ms := Ms}) ->
  #{message_id => Id, conversation_id => C, sender_id => Sd, client_message_id => Cm, text => T,
    created_at_unix_ms => Ms, seq => S}.

conversation_to_pb(#{id := Id, kind := Kind, title := Title, last_seq := L, last_activity_ms := Act,
                     members := Members}) ->
  #{conversation_id => Id, kind => kind(Kind), title => Title, last_seq => L, last_activity_unix_ms => Act,
    members => [#{user_id => U, username => Un, display_name => Dn, delivered_up_to_seq => D, read_up_to_seq => R,
                  role => role(Role)}
                || #{user_id := U, username := Un, display_name := Dn, delivered_seq := D, read_seq := R,
                     role := Role} <- Members]}.

role(owner) -> 'MEMBER_ROLE_OWNER';
role(admin) -> 'MEMBER_ROLE_ADMIN';
role(member) -> 'MEMBER_ROLE_MEMBER'.

kind(direct) -> 'CONVERSATION_KIND_DIRECT';
kind(group) -> 'CONVERSATION_KIND_GROUP'.

%% ------------------------------------------------------------------ domain error -> protocol error
error_code(invalid) -> 'ERROR_CODE_INVALID_ARGUMENT';
error_code(group_full) -> 'ERROR_CODE_INVALID_ARGUMENT';
error_code(not_a_group) -> 'ERROR_CODE_INVALID_ARGUMENT';
error_code(forbidden) -> 'ERROR_CODE_PERMISSION_DENIED';
error_code(not_found) -> 'ERROR_CODE_NOT_FOUND';
error_code(rate_limited) -> 'ERROR_CODE_RATE_LIMITED';
error_code(unauthenticated) -> 'ERROR_CODE_UNAUTHENTICATED';
error_code(_) -> 'ERROR_CODE_INTERNAL'.
