%% @doc Password hashing via the `bcrypt` library (maintained NIF wrapper; no custom crypto here).
%% NOTE: the bcrypt API calls below are from the library README and must be confirmed on first compile.
-module(chat_password).
-export([hash/1, verify/2, dummy_verify/1]).

hash(Password) when is_binary(Password) ->
  {ok, Salt} = bcrypt:gen_salt(),
  {ok, Hash} = bcrypt:hashpw(Password, Salt),
  {ok, iolist_to_binary(Hash)}.

%% bcrypt hashes embed their salt, so hashing with the stored hash as "salt" reproduces it when equal.
verify(Password, Stored) when is_binary(Password), is_binary(Stored) ->
  try bcrypt:hashpw(Password, Stored) of
    {ok, Computed} ->
      C = iolist_to_binary(Computed),
      byte_size(C) =:= byte_size(Stored) andalso crypto:hash_equals(C, Stored);
    _ -> false
  catch _:_ -> false
  end.

%% Burn the same CPU as a real check when the user does not exist (login timing equalisation).
dummy_verify(Password) ->
  Dummy = case persistent_term:get({?MODULE, dummy}, undefined) of
    undefined -> {ok, H} = hash(<<"dummy-password-for-timing">>), persistent_term:put({?MODULE, dummy}, H), H;
    H -> H
  end,
  _ = verify(Password, Dummy),
  false.
