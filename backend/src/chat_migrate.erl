%% @doc Tiny forward-only SQL migration runner. Files priv/migrations/NNNN_name.sql are applied in name
%% order, each in its own transaction, and recorded in schema_migrations. A Postgres advisory lock stops
%% two nodes migrating at once. Used as a supervisor child: runs, then returns `ignore`.
-module(chat_migrate).
-include("chat.hrl").
-export([start_link/0, run/0]).
-define(LOCK_KEY, 727274).

start_link() ->
  case chat_config:get(run_migrations) of
    true ->
      case run() of
        ok -> ignore;
        {error, Reason} -> {error, {migration_failed, Reason}}
      end;
    false -> ignore
  end.

run() ->
  Dir = filename:join(code:priv_dir(chat), "migrations"),
  Files = lists:sort(filelib:wildcard("*.sql", Dir)),
  case chat_db:with_conn(fun(C) -> locked(C, Dir, Files) end) of
    {error, _} = E -> E;
    ok -> ok
  end.

locked(C, Dir, Files) ->
  _ = epgsql:squery(C, "SELECT pg_advisory_lock(" ++ integer_to_list(?LOCK_KEY) ++ ")"),
  try
    case ok_result(epgsql:squery(C, "CREATE TABLE IF NOT EXISTS schema_migrations ("
                                    "version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())")) of
      ok -> apply_all(C, Dir, Files);
      E -> E
    end
  after
    _ = epgsql:squery(C, "SELECT pg_advisory_unlock(" ++ integer_to_list(?LOCK_KEY) ++ ")")
  end.

apply_all(_C, _Dir, []) -> ok;
apply_all(C, Dir, [File | Rest]) ->
  Version = filename:rootname(File),
  case epgsql:equery(C, "SELECT 1 FROM schema_migrations WHERE version = $1", [Version]) of
    {ok, _, [_ | _]} -> apply_all(C, Dir, Rest);
    {ok, _, []} ->
      case apply_one(C, filename:join(Dir, File), Version) of
        ok -> ?LOG_INFO(#{event => migration_applied, version => Version}), apply_all(C, Dir, Rest);
        {error, R} -> {error, {Version, R}}
      end;
    {error, R} -> {error, R}
  end.

apply_one(C, Path, Version) ->
  {ok, Sql} = file:read_file(Path),
  _ = epgsql:squery(C, "BEGIN"),
  Result = case ok_result(epgsql:squery(C, Sql)) of
    ok -> ok_result(epgsql:equery(C, "INSERT INTO schema_migrations (version) VALUES ($1)", [Version]));
    E -> E
  end,
  case Result of
    ok -> ok_result(epgsql:squery(C, "COMMIT"));
    Err -> _ = epgsql:squery(C, "ROLLBACK"), Err
  end.

%% epgsql returns a list of results for multi-statement simple queries.
ok_result({error, E}) -> {error, E};
ok_result(L) when is_list(L) -> first_error(L);
ok_result(_) -> ok.

first_error([]) -> ok;
first_error([{error, E} | _]) -> {error, E};
first_error([_ | T]) -> first_error(T).
