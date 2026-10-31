-module(test_helpers).
-export([load_config/0, find_up/1]).

%% Loads a valid configuration without touching real environment variables.
load_config() ->
  Env = #{"CHAT_DB_NAME" => "x", "CHAT_DB_USER" => "x", "CHAT_DB_PASSWORD" => "x"},
  ok = chat_config:load(fun(K) -> maps:get(K, Env, false) end).

%% Walks up from the current directory (rebar3 runs tests from varying places under _build).
find_up(Rel) ->
  {ok, Cwd} = file:get_cwd(),
  find_up(Cwd, Rel, 12).
find_up(_Dir, _Rel, 0) -> error;
find_up(Dir, Rel, N) ->
  P = filename:join(Dir, Rel),
  case filelib:is_regular(P) of
    true -> {ok, P};
    false -> find_up(filename:dirname(Dir), Rel, N - 1)
  end.
