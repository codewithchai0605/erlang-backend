%% @doc Delivery and read receipts as per-member sequence high-water marks (ADR 0006).
%% "delivered": the recipient's device stored the message; "read": the recipient saw it.
-module(chat_delivery).
-export([ack_delivered/4, mark_read/4]).

ack_delivered(User, Conv, Seq, ExceptPid) -> advance(delivered, User, Conv, Seq, ExceptPid).
mark_read(User, Conv, Seq, ExceptPid) -> advance(read, User, Conv, Seq, ExceptPid).

advance(Kind, User, Conv, Seq, ExceptPid) ->
  case chat_repo:advance_receipt(Kind, Conv, User, Seq) of
    {ok, #{delivered_seq := D, read_seq := R}} ->
      Update = #{conversation_id => Conv, user_id => User, delivered_up_to_seq => D, read_up_to_seq => R},
      case chat_repo:member_ids(Conv) of
        {ok, Ids} -> chat_dispatch:push(Ids, chat_protocol:envelope(<<>>, {receipt, Update}), ExceptPid);
        {error, _} -> ok
      end,
      {ok, Update};
    not_member -> {error, forbidden};
    {error, _} -> {error, internal}
  end.
