%% @doc Registration, login, token refresh and session authentication.
%%
%% Opaque-token design (ADR 0004): access and refresh tokens are 256-bit random strings; only their
%% SHA-256 hashes are stored. Refresh tokens ROTATE on every use; presenting an already-rotated token
%% revokes the whole session (token theft detection).
-module(chat_auth).
-include("chat.hrl").
-export([register/2, login/2, refresh/1, authenticate/1, logout/2, logout_all/1]).

%% @param Device #{platform => binary(), label => binary()}
register(#{username := U0, password := P0, display_name := D0}, Device) ->
  case {chat_validate:username(U0), chat_validate:password(P0), chat_validate:display_name(D0)} of
    {{ok, U}, {ok, P}, {ok, D}} ->
      {ok, Hash} = chat_password:hash(P),
      case chat_repo:create_user(#{username => U, display_name => D, password_hash => Hash}) of
        {ok, User} -> issue(User, Device);
        {error, username_taken} -> {error, username_taken};
        {error, _} -> {error, internal}
      end;
    {{error, _}, _, _} -> {error, {invalid, username}};
    {_, {error, _}, _} -> {error, {invalid, password}};
    _ -> {error, {invalid, display_name}}
  end.

login(#{username := U0, password := P}, Device) when is_binary(P) ->
  case chat_validate:username(U0) of
    {ok, U} ->
      case chat_repo:find_user_by_username(U) of
        {ok, #{password_hash := Hash} = User} ->
          case chat_password:verify(P, Hash) of
            true -> issue(maps:without([password_hash], User), Device);
            false -> {error, invalid_credentials}
          end;
        not_found -> chat_password:dummy_verify(P), {error, invalid_credentials};
        {error, _} -> {error, internal}
      end;
    {error, _} -> chat_password:dummy_verify(P), {error, invalid_credentials}
  end;
login(_, _) -> {error, invalid_credentials}.

refresh(Token) when is_binary(Token) ->
  H = hash_token(Token),
  case chat_repo:find_session_by_refresh(H) of
    {ok, #{id := Id, user_id := Uid, is_current := true, refresh_valid := true}} ->
      {Access, AH} = new_token(),
      {Refresh, RH} = new_token(),
      case chat_repo:rotate_session(Id, H, AH, RH, chat_config:get(access_ttl_s), chat_config:get(refresh_ttl_s)) of
        ok -> {ok, #{user_id => Uid, tokens => tokens(Access, Refresh)}};
        {error, stale} -> {error, invalid_refresh};
        {error, _} -> {error, internal}
      end;
    {ok, #{id := Id, user_id := Uid, is_current := false}} ->
      ?LOG_WARNING(#{event => refresh_token_reuse_detected, session_id => Id}),
      _ = chat_repo:revoke_session(Id),
      chat_dispatch:revoke_session(Uid, Id),
      {error, invalid_refresh};
    {ok, _} -> {error, invalid_refresh};
    not_found -> {error, invalid_refresh};
    {error, _} -> {error, internal}
  end;
refresh(_) -> {error, invalid_refresh}.

authenticate(Token) when is_binary(Token) ->
  case chat_repo:find_session_by_access(hash_token(Token)) of
    {ok, #{id := Sid, user_id := Uid}} -> {ok, #{session_id => Sid, user_id => Uid}};
    not_found -> {error, unauthenticated};
    {error, _} -> {error, internal}
  end;
authenticate(_) -> {error, unauthenticated}.

logout(UserId, SessionId) ->
  _ = chat_repo:revoke_session(SessionId),
  chat_dispatch:revoke_session(UserId, SessionId),
  ok.

logout_all(UserId) ->
  case chat_repo:revoke_all_sessions(UserId) of
    {ok, Ids} -> [chat_dispatch:revoke_session(UserId, Id) || Id <- Ids], ok;
    {error, _} -> {error, internal}
  end.

%% ---------------------------------------------------------------- internals
issue(#{id := UserId} = User, Device) ->
  Platform = maps:get(platform, Device, <<"unknown">>),
  Label = maps:get(label, Device, null),
  {Access, AH} = new_token(),
  {Refresh, RH} = new_token(),
  case chat_repo:create_device(UserId, Platform, Label) of
    {ok, DeviceId} ->
      case chat_repo:create_session(#{user_id => UserId, device_id => DeviceId, access_hash => AH,
                                      access_ttl_s => chat_config:get(access_ttl_s), refresh_hash => RH,
                                      refresh_ttl_s => chat_config:get(refresh_ttl_s)}) of
        {ok, _SessionId} -> {ok, #{user => User, tokens => tokens(Access, Refresh)}};
        {error, _} -> {error, internal}
      end;
    {error, _} -> {error, internal}
  end.

new_token() ->
  T = base64:encode(crypto:strong_rand_bytes(32), #{mode => urlsafe, padding => false}),
  {T, hash_token(T)}.

hash_token(T) -> crypto:hash(sha256, T).

tokens(Access, Refresh) ->
  #{access_token => Access, access_expires_in => chat_config:get(access_ttl_s),
    refresh_token => Refresh, refresh_expires_in => chat_config:get(refresh_ttl_s)}.
