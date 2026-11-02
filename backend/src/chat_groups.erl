%% @doc Group conversation use-cases and their authorization rules.
%%
%%   create        any user               creator becomes `owner`
%%   add_members   owner only             new members see history only from the moment they join
%%   remove_member owner only             cannot remove yourself (use leave); the target gets conversation_removed
%%   rename        owner only
%%   leave         any member             ownership passes to the longest-standing member; an empty group is deleted
%%
%% Direct conversations cannot be modified (`invalid`). Authorization is ALWAYS decided from the database
%% (chat_conversations:require_member/2), never from client-supplied claims or caches.
%% After every change the current members receive the updated ConversationInfo through chat_dispatch;
%% the requesting connection gets the same data as its reply instead (ExceptPid).
-module(chat_groups).
-export([create/4, add_members/4, remove_member/4, leave/3, rename/4]).

create(User, Title, MemberIds, ExceptPid) ->
  Others = [M || M <- lists:usort(MemberIds), M =/= User],
  Max = chat_config:get(max_group_members),
  with_rate_limit(User, fun() ->
    if
      Others =:= [] -> {error, invalid};
      length(Others) + 1 > Max -> {error, group_full};
      true ->
        case chat_repo:create_group(User, Title, Others) of
          {ok, Id} ->
            chat_metrics:inc(groups_created_total),
            announce(Id, ExceptPid);
          {error, unknown_user} -> {error, not_found};
          {error, _} -> {error, internal}
        end
    end
  end).

add_members(User, Conv, UserIds, ExceptPid) ->
  with_owner(User, Conv, fun(_Info) ->
    case chat_repo:add_members(Conv, UserIds, chat_config:get(max_group_members)) of
      {ok, _Added} -> announce(Conv, ExceptPid);
      {error, unknown_user} -> {error, not_found};
      {error, Reason} when Reason =:= not_found; Reason =:= not_a_group; Reason =:= group_full -> {error, Reason};
      {error, _} -> {error, internal}
    end
  end).

remove_member(User, Conv, Target, ExceptPid) when User =/= Target ->
  with_owner(User, Conv, fun(_Info) ->
    case chat_repo:remove_member(Conv, Target) of
      {ok, _} ->
        removed(Target, Conv, undefined),
        announce(Conv, ExceptPid);
      {error, not_member} -> {error, not_found};
      {error, not_found} -> {error, not_found};
      {error, _} -> {error, internal}
    end
  end);
remove_member(_User, _Conv, _Self, _ExceptPid) -> {error, invalid}.     %% the owner leaves via leave/3

%% @doc Returns ok; the caller replies with ConversationRemoved.
leave(User, Conv, ExceptPid) ->
  with_rate_limit(User, fun() ->
    case chat_conversations:require_member(User, Conv) of
      {ok, #{kind := group}} ->
        case chat_repo:remove_member(Conv, User) of
          {ok, #{conversation_deleted := true}} ->
            removed(User, Conv, ExceptPid), ok;
          {ok, _} ->
            removed(User, Conv, ExceptPid),    %% the user's OTHER devices
            _ = announce(Conv, undefined),
            ok;
          {error, Reason} when Reason =:= not_member; Reason =:= not_found -> {error, forbidden};
          {error, _} -> {error, internal}
        end;
      {ok, _Direct} -> {error, invalid};
      {error, _} = E -> E
    end
  end).

rename(User, Conv, Title, ExceptPid) ->
  with_owner(User, Conv, fun(_Info) ->
    case chat_repo:rename_conversation(Conv, Title) of
      ok -> announce(Conv, ExceptPid);
      not_found -> {error, not_found};
      {error, _} -> {error, internal}
    end
  end).

%% ------------------------------------------------------------------ internals
with_rate_limit(User, Fun) ->
  case chat_rate_limit:check(group, User, chat_config:get(rate_group_per_min), 60000) of
    ok -> Fun();
    {error, rate_limited} -> {error, rate_limited}
  end.

with_owner(User, Conv, Fun) ->
  with_rate_limit(User, fun() ->
    case chat_conversations:require_member(User, Conv) of
      {ok, #{kind := group, members := Ms} = Info} ->
        case [U || #{user_id := U, role := owner} <- Ms, U =:= User] of
          [_] -> Fun(Info);
          [] -> {error, forbidden}
        end;
      {ok, _Direct} -> {error, invalid};
      {error, _} = E -> E
    end
  end).

%% Reload the conversation and push it to every current member; the requester gets it as {ok, Info}.
announce(Conv, ExceptPid) ->
  case chat_repo:get_conversation(Conv) of
    {ok, #{members := Ms} = Info} ->
      Env = chat_protocol:envelope(<<>>, {conversation, chat_protocol:conversation_to_pb(Info)}),
      chat_dispatch:push([U || #{user_id := U} <- Ms], Env, ExceptPid),
      {ok, Info};
    _ -> {error, internal}
  end.

removed(User, Conv, ExceptPid) ->
  Env = chat_protocol:envelope(<<>>, {conversation_removed, #{conversation_id => Conv}}),
  chat_dispatch:push([User], Env, ExceptPid).
