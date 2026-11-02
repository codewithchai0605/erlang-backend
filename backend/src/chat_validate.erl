%% @doc Input validation. Pure functions returning {ok, Normalised} | {error, Reason}.
%% Rule: validate semantics AFTER decoding (JSON or Protobuf only guarantee the shape, not the content).
-module(chat_validate).
-export([username/1, password/1, display_name/1, group_title/1, text/1, uuid/1, uuid_list/2, client_message_id/1, token/1]).

username(B) when is_binary(B) ->
  L = unicode:characters_to_binary(string:lowercase(string:trim(B))),
  case is_binary(L) andalso re:run(L, "^[a-z0-9_]{3,32}$", [{capture, none}]) of
    match -> {ok, L};
    _ -> {error, invalid_username}
  end;
username(_) -> {error, invalid_username}.

%% bcrypt only uses the first 72 bytes, so longer passwords are rejected instead of silently truncated.
password(B) when is_binary(B), byte_size(B) >= 8, byte_size(B) =< 72 ->
  case unicode:characters_to_binary(B) of
    B -> {ok, B};
    _ -> {error, invalid_password}
  end;
password(_) -> {error, invalid_password}.

display_name(B) when is_binary(B) ->
  case unicode:characters_to_binary(string:trim(B)) of
    T when is_binary(T), T =/= <<>> ->
      case string:length(T) =< 50 andalso not has_control(T) of
        true -> {ok, T};
        false -> {error, invalid_display_name}
      end;
    _ -> {error, invalid_display_name}
  end;
display_name(_) -> {error, invalid_display_name}.

%% Group titles: like display names but up to 100 characters (the database CHECK allows the same bound).
group_title(B) when is_binary(B) ->
  case unicode:characters_to_binary(string:trim(B)) of
    T when is_binary(T), T =/= <<>> ->
      case string:length(T) =< 100 andalso not has_control(T) of
        true -> {ok, T};
        false -> {error, invalid_group_title}
      end;
    _ -> {error, invalid_group_title}
  end;
group_title(_) -> {error, invalid_group_title}.

%% A bounded list of UUIDs, normalised and de-duplicated. Max bounds the work an attacker can request.
uuid_list(L, Max) when is_list(L), length(L) =< Max ->
  Results = [uuid(X) || X <- L],
  case lists:all(fun({ok, _}) -> true; (_) -> false end, Results) of
    true -> {ok, lists:usort([U || {ok, U} <- Results])};
    false -> {error, invalid_id}
  end;
uuid_list(_, _) -> {error, invalid_id}.

%% Message text: valid UTF-8, no NUL (PostgreSQL text cannot hold it), not blank, bounded.
text(B) when is_binary(B), byte_size(B) =< 65536 ->
  case unicode:characters_to_binary(B) of
    B ->
      Ok = binary:match(B, <<0>>) =:= nomatch
           andalso string:trim(B) =/= <<>>
           andalso string:length(B) =< chat_config:get(max_text_chars),
      case Ok of true -> {ok, B}; false -> {error, invalid_text} end;
    _ -> {error, invalid_text}
  end;
text(_) -> {error, invalid_text}.

uuid(B) when is_binary(B), byte_size(B) =:= 36 ->
  L = string:lowercase(B),
  case re:run(L, "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", [{capture, none}]) of
    match -> {ok, L};
    nomatch -> {error, invalid_id}
  end;
uuid(_) -> {error, invalid_id}.

client_message_id(B) when is_binary(B), byte_size(B) >= 1, byte_size(B) =< 64 ->
  case re:run(B, "^[A-Za-z0-9_-]+$", [{capture, none}]) of
    match -> {ok, B};
    nomatch -> {error, invalid_client_message_id}
  end;
client_message_id(_) -> {error, invalid_client_message_id}.

token(B) when is_binary(B), byte_size(B) >= 1, byte_size(B) =< 512 -> {ok, B};
token(_) -> {error, invalid_token}.

has_control(B) -> re:run(B, "[\\x00-\\x1f\\x7f]", [{capture, none}]) =:= match.
