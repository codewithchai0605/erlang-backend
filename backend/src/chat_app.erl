%% @doc Application callback. Loads and validates configuration BEFORE starting the supervision tree so
%% that bad configuration fails fast with a readable message instead of crashing deep inside a worker.
-module(chat_app).
-behaviour(application).
-include("chat.hrl").
-export([start/2, prep_stop/1, stop/1]).

start(_Type, _Args) ->
  case chat_config:load() of
    ok ->
      chat_metrics:init(),
      chat_sup:start_link();
    {error, Problems} ->
      ?LOG_ERROR(#{event => invalid_config, problems => Problems}),
      {error, {invalid_config, Problems}}
  end.

%% Called before the tree is stopped: tell every WebSocket to close with 1001 (going away).
prep_stop(State) ->
  chat_dispatch:close_all(),
  State.

stop(_State) -> ok.
