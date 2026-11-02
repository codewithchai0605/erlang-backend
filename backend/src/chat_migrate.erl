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
  case chat_db:with_conn(fun(C) -> run(C, Dir, Files) end) of
    {error, _} = E -> E;
    ok -> ok
  end.

%% Every step runs inside its own transaction holding pg_advisory_xact_lock, which is released
%% automatically at COMMIT/ROLLBACK. Unlike a session-level lock this is safe behind a transaction-pooling
%% proxy (PgBouncer, Neon's "-pooler" endpoints), where consecutive statements may reach different backends.
run(C, Dir, Files) ->
  case in_tx(C, fun() ->
         ok_result(epgsql:squery(C, "CREATE TABLE IF NOT EXISTS schema_migrations ("
                                    "version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())"))
       end) of
    ok -> apply_all(C, Dir, Files);
    E -> E
  end.

apply_all(_C, _Dir, []) -> ok;
apply_all(C, Dir, [File | Rest]) ->
  Version = filename:rootname(File),
  case apply_one(C, filename:join(Dir, File), Version) of
    applied -> ?LOG_INFO(#{event => migration_applied, version => Version}), apply_all(C, Dir, Rest);
    skipped -> apply_all(C, Dir, Rest);
    {error, R} -> {error, {Version, R}}
  end.

apply_one(C, Path, Version) ->
  {ok, Sql} = file:read_file(Path),
  in_tx(C, fun() ->
    case epgsql:equery(C, "SELECT 1 FROM schema_migrations WHERE version = $1", [Version]) of
      {ok, _, [_ | _]} -> skipped;      %% another node (or an earlier boot) already applied it
      {ok, _, []} ->
        case ok_result(epgsql:squery(C, Sql)) of
          ok ->
            case ok_result(epgsql:equery(C, "INSERT INTO schema_migrations (version) VALUES ($1)", [Version])) of
              ok -> applied;
              E -> E
            end;
          E -> E
        end;
      {error, _} = E -> E
    end
  end).

%% BEGIN; take the lock; run Fun; COMMIT on ok/applied/skipped, ROLLBACK on anything else.
in_tx(C, Fun) ->
  _ = epgsql:squery(C, "BEGIN"),
  Result = try
    case ok_result(epgsql:squery(C, "SELECT pg_advisory_xact_lock(" ++ integer_to_list(?LOCK_KEY) ++ ")")) of
      ok -> Fun();
      E -> E
    end
  catch Class:Reason -> {error, {Class, Reason}}
  end,
  case Result of
    R when R =:= ok; R =:= applied; R =:= skipped ->
      case ok_result(epgsql:squery(C, "COMMIT")) of ok -> R; Err -> Err end;
    Failed ->
      _ = epgsql:squery(C, "ROLLBACK"),
      Failed
  end.

%% epgsql returns a list of results for multi-statement simple queries.
ok_result({error, E}) -> {error, E};
ok_result(L) when is_list(L) -> first_error(L);
ok_result(_) -> ok.

first_error([]) -> ok;
first_error([{error, E} | _]) -> {error, E};
first_error([_ | T]) -> first_error(T).
