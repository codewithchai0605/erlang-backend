%% @doc User profile operations (HTTP only).
-module(chat_users).
-export([get/1, lookup/1, update_display_name/2]).

get(UserId) ->
  case chat_repo:get_user(UserId) of
    {ok, U} -> {ok, U};
    not_found -> {error, not_found};
    {error, _} -> {error, internal}
  end.

lookup(Username0) ->
  case chat_validate:username(Username0) of
    {ok, U} ->
      case chat_repo:find_user_by_username(U) of
        {ok, #{id := Id, username := Un, display_name := Dn}} -> {ok, #{id => Id, username => Un, display_name => Dn}};
        not_found -> {error, not_found};
        {error, _} -> {error, internal}
      end;
    {error, _} -> {error, not_found}
  end.

update_display_name(UserId, Name0) ->
  case chat_validate:display_name(Name0) of
    {ok, Name} ->
      case chat_repo:update_display_name(UserId, Name) of
        {ok, U} -> {ok, U};
        not_found -> {error, not_found};
        {error, _} -> {error, internal}
      end;
    {error, _} -> {error, {invalid, display_name}}
  end.
