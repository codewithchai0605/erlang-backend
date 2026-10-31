%% @doc Thin database access layer over the pool. Domain code never calls poolboy/epgsql directly; it
%% goes through chat_repo -> chat_repo_pg -> this module.
%%
%% Error handling convention: results are the usual epgsql shapes, but SQL errors become
%% {error, {db, SqlState}} (the SQLSTATE only; messages can contain user data so they are not logged).
-module(chat_db).
-include("chat.hrl").
-include_lib("epgsql/include/epgsql.hrl").
-export([with_conn/1, q/2, equery/3, transaction/1, must/1, ping/0]).

%% @doc Run Fun(Connection) with an exclusively checked-out connection.
with_conn(Fun) ->
  try
    poolboy:transaction(?DB_POOL, fun(Worker) ->
      case gen_server:call(Worker, get_conn, 10000) of
        {ok, C} -> run(Worker, C, Fun);
        {error, _} -> {error, db_unavailable}
      end
    end, 5000)
  catch
    exit:{Reason, _} when Reason =:= timeout; Reason =:= noproc -> {error, db_unavailable}
  end.

run(Worker, C, Fun) ->
  try Fun(C)
  catch
    throw:Thrown -> erlang:throw(Thrown);
    Class:Reason:Stack ->
      gen_server:cast(Worker, reset),
      erlang:raise(Class, Reason, Stack)
  end.

q(Sql, Params) -> with_conn(fun(C) -> equery(C, Sql, Params) end).

equery(C, Sql, Params) ->
  case epgsql:equery(C, Sql, Params) of
    {error, #error{code = Code}} ->
      ?LOG_ERROR(#{event => db_error, sqlstate => Code}),
      {error, {db, Code}};
    Result -> Result
  end.

%% @doc Run Fun(Connection) in a transaction. Use must/1 or throw({abort, Reason}) to roll back;
%% the result is Fun's value or {error, Reason} after an abort.
transaction(Fun) ->
  with_conn(fun(C) ->
    try epgsql:with_transaction(C, Fun)
    catch throw:{abort, Reason} -> {error, Reason}
    end
  end).

must({error, Reason}) -> throw({abort, Reason});
must(Other) -> Other.

ping() ->
  case q("SELECT 1", []) of
    {ok, _, [{1}]} -> ok;
    _ -> {error, db_unavailable}
  end.
