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
    %% Dynamic supervisor for fire-and-forget tasks (presence fan-out). Before presence, which uses it.
    #{id => chat_task_sup, start => {chat_task_sup, start_link, []}, restart => permanent, type => supervisor},
    chat_http_listener:child_spec(),
    %% LAST on purpose: with rest_for_one a presence crash restarts only presence itself (it rebuilds its
    %% state from the `pg` scope), never the listener or the live connections.
    #{id => chat_presence, start => {chat_presence, start_link, []}, restart => permanent, shutdown => 10000, type => worker}
  ],
  {ok, {SupFlags, Children}}.
