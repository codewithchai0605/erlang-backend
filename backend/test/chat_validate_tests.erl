-module(chat_validate_tests).
-include_lib("eunit/include/eunit.hrl").

setup() -> test_helpers:load_config().

username_test() ->
  ?assertEqual({ok, <<"alice_1">>}, chat_validate:username(<<"  Alice_1 ">>)),
  ?assertMatch({error, _}, chat_validate:username(<<"ab">>)),
  ?assertMatch({error, _}, chat_validate:username(<<"has space">>)),
  ?assertMatch({error, _}, chat_validate:username(<<"semi;colon">>)),
  ?assertMatch({error, _}, chat_validate:username(not_a_binary)).

password_bounds_test() ->
  ?assertMatch({ok, _}, chat_validate:password(<<"12345678">>)),
  ?assertMatch({error, _}, chat_validate:password(<<"1234567">>)),
  ?assertMatch({error, _}, chat_validate:password(binary:copy(<<"a">>, 73))),
  ?assertMatch({error, _}, chat_validate:password(<<255, 255, 255, 255, 255, 255, 255, 255>>)).

display_name_test() ->
  ?assertEqual({ok, <<"Alice B">>}, chat_validate:display_name(<<"  Alice B ">>)),
  ?assertMatch({error, _}, chat_validate:display_name(<<"   ">>)),
  ?assertMatch({error, _}, chat_validate:display_name(<<"bad", 0, "name">>)),
  ?assertMatch({error, _}, chat_validate:display_name(binary:copy(<<"x">>, 51))).

text_test_() ->
  {setup, fun setup/0, fun(_) -> ok end, [
    ?_assertMatch({ok, _}, chat_validate:text(<<"hello">>)),
    ?_assertMatch({ok, _}, chat_validate:text(unicode:characters_to_binary("héllo ✓"))),
    ?_assertMatch({error, _}, chat_validate:text(<<>>)),
    ?_assertMatch({error, _}, chat_validate:text(<<"   ">>)),
    ?_assertMatch({error, _}, chat_validate:text(<<"nul", 0, "byte">>)),
    ?_assertMatch({error, _}, chat_validate:text(<<255, 254>>)),
    ?_assertMatch({error, _}, chat_validate:text(binary:copy(<<"a">>, 4001)))
  ]}.

uuid_test() ->
  ?assertEqual({ok, <<"123e4567-e89b-12d3-a456-426614174000">>},
               chat_validate:uuid(<<"123E4567-E89B-12D3-A456-426614174000">>)),
  ?assertMatch({error, _}, chat_validate:uuid(<<"not-a-uuid">>)),
  ?assertMatch({error, _}, chat_validate:uuid(<<"123e4567-e89b-12d3-a456-42661417400g">>)).

client_message_id_test() ->
  ?assertMatch({ok, _}, chat_validate:client_message_id(<<"a1-B2_c3">>)),
  ?assertMatch({error, _}, chat_validate:client_message_id(<<>>)),
  ?assertMatch({error, _}, chat_validate:client_message_id(<<"has space">>)),
  ?assertMatch({error, _}, chat_validate:client_message_id(binary:copy(<<"a">>, 65))).

group_title_test() ->
  ?assertEqual({ok, <<"Team A">>}, chat_validate:group_title(<<"  Team A ">>)),
  ?assertEqual({ok, binary:copy(<<"x">>, 100)}, chat_validate:group_title(binary:copy(<<"x">>, 100))),
  ?assertMatch({error, _}, chat_validate:group_title(binary:copy(<<"x">>, 101))),
  ?assertMatch({error, _}, chat_validate:group_title(<<"   ">>)),
  ?assertMatch({error, _}, chat_validate:group_title(<<"bad", 0, "title">>)),
  ?assertMatch({error, _}, chat_validate:group_title(<<"new\nline">>)),
  ?assertMatch({error, _}, chat_validate:group_title(undefined)).

uuid_list_test() ->
  A = <<"123e4567-e89b-12d3-a456-426614174000">>,
  ?assertEqual({ok, [A]}, chat_validate:uuid_list([A, string:uppercase(A), A], 5)),
  ?assertEqual({ok, []}, chat_validate:uuid_list([], 5)),
  ?assertMatch({error, _}, chat_validate:uuid_list([A, <<"nope">>], 5)),
  ?assertMatch({error, _}, chat_validate:uuid_list([A, A, A], 2)),       %% bound applies BEFORE de-duplication
  ?assertMatch({error, _}, chat_validate:uuid_list(not_a_list, 5)).
