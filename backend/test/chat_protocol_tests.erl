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
                              created_at_unix_ms => 1700000000000, seq => 6}}}}
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

typing_is_unsupported_until_milestone_5_test() ->
  ?assertMatch({error, 'ERROR_CODE_UNSUPPORTED_EVENT', _}, chat_protocol:validate({typing, #{}})).

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
