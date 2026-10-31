%% @doc Conversation use-cases. Authorization rule used everywhere: a user may touch a conversation only
%% if they are a member; non-members get `forbidden`, unknown ids get `not_found`.
-module(chat_conversations).
-export([create_direct/3, list/1, require_member/2]).

%% @doc Find-or-create the direct conversation between User and Peer; notifies both users' live connections.
create_direct(User, Peer, ExceptPid) when User =/= Peer ->
  case chat_repo:get_user(Peer) of
    {ok, _} ->
      case chat_repo:create_or_get_direct(User, Peer) of
        {ok, ConvId} ->
          case chat_repo:get_conversation(ConvId) of
            {ok, Info} ->
              chat_dispatch:push([User, Peer],
                chat_protocol:envelope(<<>>, {conversation, chat_protocol:conversation_to_pb(Info)}), ExceptPid),
              {ok, Info};
            _ -> {error, internal}
          end;
        {error, _} -> {error, internal}
      end;
    not_found -> {error, not_found};
    {error, _} -> {error, internal}
  end;
create_direct(_, _, _) -> {error, invalid}.

list(User) ->
  case chat_repo:list_conversations(User) of
    {ok, Convs} -> {ok, Convs};
    {error, _} -> {error, internal}
  end.

require_member(User, ConvId) ->
  case chat_repo:get_conversation(ConvId) of
    {ok, #{members := Members} = Info} ->
      case lists:any(fun(#{user_id := U}) -> U =:= User end, Members) of
        true -> {ok, Info};
        false -> {error, forbidden}
      end;
    not_found -> {error, not_found};
    {error, _} -> {error, internal}
  end.
