-module(chat_protocol_tests).
-include_lib("eunit/include/eunit.hrl").

-define(UUID, <<"123e4567-e89b-12d3-a456-426614174000">>).

%% name => {ProtoMessageName, Map}; the hex bytes live in proto/testdata/golden_vectors.json and are shared
%% with the Dart tests, so both implementations are checked against the same independent encoder.
vectors() -> #{
  <<"client_hello">> => {'ClientEnvelope', #{request_id => <<"r1">>,
      body => {hello, #{protocol_version => 1, capabilities => [<<"typing">>], access_token => <<"tok">>}}}},
  <<"client_send_message">> => {'ClientEnvelope', #{request_id => <<"r2">>,
      body => {send_message, #{conversation_id => <<"c1">>, client_message_id => <<"m1">>, text => <<"hi">>}}}},
  <<"server_accepted">> => {'ServerEnvelope', #{request_id => <<"r2">>,
      body => {accepted, #{message_id => <<"x">>, client_message_id => <<"m1">>, seq => 5,
                           created_at_unix_ms => 1700000000000, conversation_id => <<"c1">>}}}},
  <<"server_error">> => {'ServerEnvelope', #{request_id => <<"r3">>,
      body => {error, #{code => 'ERROR_CODE_INVALID_ARGUMENT', message => <<"bad">>}}}},
  <<"server_new_message">> => {'ServerEnvelope', #{
      body => {new_message, #{message_id => <<"x">>, conversation_id => <<"c1">>, sender_id => <<"u1">>,
                              client_message_id => <<"m1">>, text => unicode:characters_to_binary("héllo"),
                              created_at_unix_ms => 1700000000000, seq => 6}}}},
  %% ---- Milestone 5: proto3 omits default values, so a map holding only non-defaults encodes identically
  <<"client_typing">> => {'ClientEnvelope', #{body => {typing, #{conversation_id => <<"c1">>, is_typing => true}}}},
  <<"client_create_group">> => {'ClientEnvelope', #{request_id => <<"r4">>,
      body => {create_group, #{title => <<"Team">>, member_user_ids => [<<"u2">>, <<"u3">>]}}}},
  <<"client_get_presence">> => {'ClientEnvelope', #{request_id => <<"r5">>, body => {get_presence, #{}}}},
  <<"server_typing_update">> => {'ServerEnvelope', #{
      body => {typing, #{conversation_id => <<"c1">>, user_id => <<"u2">>, is_typing => true}}}},
  <<"server_presence_update">> => {'ServerEnvelope', #{
      body => {presence, #{user_id => <<"u2">>, online => false, last_seen_unix_ms => 1700000000000}}}},
  <<"server_presence_snapshot">> => {'ServerEnvelope', #{request_id => <<"r5">>,
      body => {presence_snapshot, #{users => [#{user_id => <<"u2">>, online => true},
                                              #{user_id => <<"u3">>, last_seen_unix_ms => 1700000000000}]}}}},
  <<"server_conversation_group">> => {'ServerEnvelope', #{request_id => <<"r4">>,
      body => {conversation, #{conversation_id => <<"c9">>, kind => 'CONVERSATION_KIND_GROUP', title => <<"Team">>,
          members => [#{user_id => <<"u1">>, username => <<"alice">>, display_name => <<"Alice">>,
                        delivered_up_to_seq => 2, read_up_to_seq => 1, role => 'MEMBER_ROLE_OWNER'},
                      #{user_id => <<"u2">>, username => <<"bob">>, display_name => <<"Bob">>, role => 'MEMBER_ROLE_MEMBER'}],
          last_seq => 3, last_activity_unix_ms => 1700000000000}}}},
  <<"server_conversation_removed">> => {'ServerEnvelope', #{body => {conversation_removed, #{conversation_id => <<"c9">>}}}}
}.

golden_vectors_test_() ->
  {ok, Path} = test_helpers:find_up("proto/testdata/golden_vectors.json"),
  {ok, Json} = file:read_file(Path),
  #{<<"vectors">> := Vs} = json:decode(Json),
  Known = vectors(),
  [{binary_to_list(Name), fun() ->
      {MsgName, Map} = maps:get(Name, Known),
      Bin = binary:decode_hex(Hex),
      ?assertEqual(Bin, iolist_to_binary(chat_pb:encode_msg(Map, MsgName))),
      %% decode then re-encode must reproduce the same canonical bytes
      ?assertEqual(Bin, iolist_to_binary(chat_pb:encode_msg(chat_pb:decode_msg(Bin, MsgName), MsgName)))
    end} || #{<<"name">> := Name, <<"hex">> := Hex} <- Vs].

garbage_is_malformed_test() ->
  ?assertEqual({error, malformed}, chat_protocol:decode_client(<<255, 255, 255, 255>>)),
  ?assertEqual({error, malformed}, chat_protocol:decode_client(<<10, 200, 1>>)).   %% length-prefix longer than data

empty_envelope_is_unsupported_test() ->
  {ok, <<>>, none} = chat_protocol:decode_client(<<>>),
  ?assertMatch({error, 'ERROR_CODE_UNSUPPORTED_EVENT', _}, chat_protocol:validate(none)).

-define(UUID2, <<"223e4567-e89b-12d3-a456-426614174000">>).
-define(INVALID, {error, 'ERROR_CODE_INVALID_ARGUMENT', _}).

validate_typing_test() ->
  ok = test_helpers:load_config(),
  ?assertMatch({ok, {typing, #{conversation_id := ?UUID, is_typing := true}}},
               chat_protocol:validate({typing, #{conversation_id => ?UUID, is_typing => true}})),
  ?assertMatch(?INVALID, chat_protocol:validate({typing, #{conversation_id => <<"x">>, is_typing => true}})),
  ?assertMatch(?INVALID, chat_protocol:validate({typing, #{conversation_id => ?UUID, is_typing => <<"yes">>}})).

validate_create_group_test() ->
  ok = test_helpers:load_config(),
  Good = #{title => <<"  Team  ">>, member_user_ids => [?UUID2, string:uppercase(?UUID2), ?UUID]},
  {ok, {create_group, #{title := <<"Team">>, member_user_ids := Ids}}} = chat_protocol:validate({create_group, Good}),
  ?assertEqual(2, length(Ids)),                                       %% normalised + de-duplicated
  ?assertMatch(?INVALID, chat_protocol:validate({create_group, Good#{title => <<"   ">>}})),
  ?assertMatch(?INVALID, chat_protocol:validate({create_group, Good#{member_user_ids => [<<"nope">>]}})),
  TooMany = [iolist_to_binary(io_lib:format("~8.16.0b-0000-4000-8000-000000000000", [N])) || N <- lists:seq(1, 101)],
  ?assertMatch(?INVALID, chat_protocol:validate({create_group, Good#{member_user_ids => TooMany}})).

validate_group_management_test() ->
  ok = test_helpers:load_config(),
  ?assertMatch({ok, {add_members, _}}, chat_protocol:validate({add_members, #{conversation_id => ?UUID, user_ids => [?UUID2]}})),
  ?assertMatch(?INVALID, chat_protocol:validate({add_members, #{conversation_id => ?UUID, user_ids => []}})),
  ?assertMatch({ok, {remove_member, _}}, chat_protocol:validate({remove_member, #{conversation_id => ?UUID, user_id => ?UUID2}})),
  ?assertMatch(?INVALID, chat_protocol:validate({remove_member, #{conversation_id => ?UUID, user_id => <<>>}})),
  ?assertMatch({ok, {leave_conversation, _}}, chat_protocol:validate({leave_conversation, #{conversation_id => ?UUID}})),
  ?assertMatch({ok, {rename_group, #{title := <<"New">>}}},
               chat_protocol:validate({rename_group, #{conversation_id => ?UUID, title => <<"New">>}})),
  ?assertMatch(?INVALID, chat_protocol:validate({rename_group, #{conversation_id => ?UUID, title => <<>>}})).

validate_get_presence_test() ->
  ?assertMatch({ok, {get_presence, #{user_ids := []}}}, chat_protocol:validate({get_presence, #{}})),
  ?assertMatch({ok, {get_presence, #{user_ids := [?UUID]}}}, chat_protocol:validate({get_presence, #{user_ids => [?UUID]}})),
  ?assertMatch(?INVALID, chat_protocol:validate({get_presence, #{user_ids => [<<"x">>]}})).

server_events_are_not_valid_requests_test() ->
  %% a client must not be able to push server-only events into the server
  ?assertMatch({error, 'ERROR_CODE_UNSUPPORTED_EVENT', _}, chat_protocol:validate({presence, #{}})),
  ?assertMatch({error, 'ERROR_CODE_UNSUPPORTED_EVENT', _}, chat_protocol:validate({conversation_removed, #{}})).

conversation_to_pb_includes_roles_test() ->
  Info = #{id => <<"c">>, kind => group, title => <<"T">>, last_seq => 3, last_activity_ms => 9,
           members => [#{user_id => <<"u1">>, username => <<"a">>, display_name => <<"A">>, delivered_seq => 1, read_seq => 1, role => owner, from_seq => 0},
                       #{user_id => <<"u2">>, username => <<"b">>, display_name => <<"B">>, delivered_seq => 0, read_seq => 0, role => member, from_seq => 2}]},
  #{members := [#{role := R1}, #{role := R2}]} = chat_protocol:conversation_to_pb(Info),
  ?assertEqual({'MEMBER_ROLE_OWNER', 'MEMBER_ROLE_MEMBER'}, {R1, R2}).

validate_send_message_test() ->
  ok = test_helpers:load_config(),
  Good = #{conversation_id => ?UUID, client_message_id => <<"m-1">>, text => <<"hi">>},
  ?assertMatch({ok, {send_message, _}}, chat_protocol:validate({send_message, Good})),
  ?assertMatch({error, 'ERROR_CODE_INVALID_ARGUMENT', _},
               chat_protocol:validate({send_message, Good#{conversation_id => <<"nope">>}})),
  ?assertMatch({error, 'ERROR_CODE_INVALID_ARGUMENT', _},
               chat_protocol:validate({send_message, Good#{text => <<"  ">>}})).

validate_paging_clamps_limit_test() ->
  Base = #{conversation_id => ?UUID, after_seq => 0},
  {ok, {sync_request, #{limit := L1}}} = chat_protocol:validate({sync_request, Base#{limit => 0}}),
  {ok, {sync_request, #{limit := L2}}} = chat_protocol:validate({sync_request, Base#{limit => 5000}}),
  ?assertEqual(50, L1),
  ?assertEqual(100, L2),
  ?assertMatch({error, _, _}, chat_protocol:validate({sync_request, Base#{after_seq => -1}})).

error_envelope_roundtrip_test() ->
  Env = chat_protocol:error_envelope(<<"r9">>, 'ERROR_CODE_RATE_LIMITED', <<"slow down">>),
  Dec = chat_pb:decode_msg(chat_protocol:encode_server(Env), 'ServerEnvelope'),
  ?assertMatch(#{request_id := <<"r9">>, body := {error, #{code := 'ERROR_CODE_RATE_LIMITED'}}}, Dec).
