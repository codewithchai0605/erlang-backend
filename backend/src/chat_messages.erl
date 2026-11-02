%% @doc Message use-cases: send (idempotent), forward sync, backward history.
-module(chat_messages).
-include("chat.hrl").
-export([send/3, sync_after/4, history_before/4]).

%% @doc Store a message and push it to every member's other live connections. Returns
%% {ok, Message, new | duplicate}. The message is durable BEFORE any push happens.
send(UserId, #{conversation_id := Conv, client_message_id := CMid, text := Text}, ExceptPid) ->
  case chat_rate_limit:check(send, UserId, chat_config:get(rate_send_per_min), 60000) of
    {error, rate_limited} -> {error, rate_limited};
    ok ->
      case chat_conversations:require_member(UserId, Conv) of
        {ok, #{members := Members}} ->
          case chat_repo:insert_message(Conv, UserId, CMid, Text) of
            {ok, Msg, new} ->
              chat_metrics:inc(messages_accepted_total),
              Env = chat_protocol:envelope(<<>>, {new_message, chat_protocol:message_to_pb(Msg)}),
              chat_dispatch:push([U || #{user_id := U} <- Members], Env, ExceptPid),
              {ok, Msg, new};
            {ok, #{conversation_id := Conv} = Msg, duplicate} ->
              chat_metrics:inc(messages_duplicate_total),
              {ok, Msg, duplicate};
            {ok, _OtherConversation, duplicate} -> {error, invalid};
            {error, _} -> {error, internal}
          end;
        {error, _} = E -> E
      end
  end.

%% @doc Messages with seq > After, ascending. Returns {ok, Messages, HasMore}.
%% A member never sees messages from before they joined (history_from_seq), see docs/decisions/0011.
sync_after(User, Conv, After, Limit) ->
  with_member(User, Conv, fun(From) ->
    case chat_repo:messages_after(Conv, max(After, From), Limit + 1) of
      {ok, Rows} -> {ok, lists:sublist(Rows, Limit), length(Rows) > Limit};
      {error, _} -> {error, internal}
    end
  end).

%% @doc Messages with seq < Before (0 = newest), returned ascending. Returns {ok, Messages, HasMore}.
%% We fetch Limit+1 rows: the extra row only tells us whether more exist, and is then dropped.
history_before(User, Conv, Before, Limit) ->
  with_member(User, Conv, fun(From) ->
    case chat_repo:messages_before(Conv, Before, From, Limit + 1) of
      {ok, Rows} -> {ok, lists:nthtail(max(0, length(Rows) - Limit), Rows), length(Rows) > Limit};
      {error, _} -> {error, internal}
    end
  end).

%% Authorisation + the caller's history boundary in one membership lookup.
with_member(User, Conv, Fun) ->
  case chat_conversations:require_member(User, Conv) of
    {ok, #{members := Members}} ->
      [From] = [F || #{user_id := U, from_seq := F} <- Members, U =:= User],
      Fun(From);
    {error, _} = E -> E
  end.
