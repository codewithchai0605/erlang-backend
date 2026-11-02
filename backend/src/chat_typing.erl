%% @doc Typing indicators: ephemeral, stateless relay. Nothing is stored; the server forwards the event to
%% the other members' live connections and forgets it. Clients expire an indicator themselves after a few
%% seconds, so a lost "stopped typing" event (disconnect, dropped push) heals on its own.
%%
%% Membership is checked against a small PER-CONNECTION cache (map owned by the WebSocket process) so a
%% fast typist does not cost one database query per keystroke. The cache expires after ?TTL_MS: after being
%% removed from a group a user could keep sending typing events for at most that long. Messages never use
%% this cache, they always check the database.
-module(chat_typing).
-export([relay/5, new_cache/0]).
-define(TTL_MS, 15000).
-define(MAX_CACHED, 32).

new_cache() -> #{}.

%% @doc relay(User, ConvId, IsTyping, ExceptPid, Cache) -> {ok | dropped, Cache1} | {error, Reason, Cache1}
%% `dropped` = rate limited (silently ignored: the indicator is cosmetic, an error reply would be noise).
relay(User, Conv, IsTyping, ExceptPid, Cache) ->
  case chat_rate_limit:check(typing, User, chat_config:get(rate_typing_per_min), 60000) of
    {error, rate_limited} -> {dropped, Cache};
    ok ->
      case members(User, Conv, Cache) of
        {ok, Ids, Cache1} ->
          chat_metrics:inc(typing_events_total),
          Env = chat_protocol:envelope(<<>>, {typing, #{conversation_id => Conv, user_id => User, is_typing => IsTyping}}),
          chat_dispatch:push([Id || Id <- Ids, Id =/= User], Env, ExceptPid),
          {ok, Cache1};
        {error, Reason} -> {error, Reason, Cache}
      end
  end.

members(User, Conv, Cache) ->
  Now = erlang:monotonic_time(millisecond),
  case Cache of
    #{Conv := {Ids, Expires}} when Expires > Now -> {ok, Ids, Cache};
    _ ->
      case chat_conversations:require_member(User, Conv) of
        {ok, #{members := Ms}} ->
          Ids = [U || #{user_id := U} <- Ms],
          Base = case map_size(Cache) >= ?MAX_CACHED of true -> #{}; false -> Cache end,
          {ok, Ids, Base#{Conv => {Ids, Now + ?TTL_MS}}};
        {error, _} = E -> E
      end
  end.
