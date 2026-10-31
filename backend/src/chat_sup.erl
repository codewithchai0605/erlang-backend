%% @doc Top supervisor. Strategy rest_for_one: children are listed in dependency order, so if an earlier
%% child dies everything started after it is restarted too (a restarted `pg` scope has lost all
%% connection groups, so the listener and its connections must restart with it).
-module(chat_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  SupFlags = #{strategy => rest_for_one, intensity => 5, period => 10},
  Children = [
    #{id => chat_pg, start => {pg, start_link, [chat_conns]}, restart => permanent, type => worker},
    #{id => chat_rate_limit, start => {chat_rate_limit, start_link, []}, restart => permanent, type => worker},
    chat_db_pool:child_spec(),
    %% Runs migrations then returns `ignore` (no process stays alive). A failed migration fails startup.
    #{id => chat_migrate, start => {chat_migrate, start_link, []}, restart => temporary, type => worker},
    chat_http_listener:child_spec()
  ],
  {ok, {SupFlags, Children}}.
