%% @doc PostgreSQL connection pool (poolboy). Each worker owns ONE epgsql connection, created lazily so the
%% application can start (and report not-ready) while the database is down.
-module(chat_db_pool).
-include("chat.hrl").
-export([child_spec/0]).

child_spec() ->
  poolboy:child_spec(?DB_POOL,
    [{name, {local, ?DB_POOL}},
     {worker_module, chat_pg_worker},
     {size, chat_config:get(db_pool_size)},
     {max_overflow, 0}],
    []).
