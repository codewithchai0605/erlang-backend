%% @doc Pool worker: holds a lazily-opened epgsql connection. A checked-out caller talks to the connection
%% directly (poolboy guarantees exclusive use), so queries do not pass through this process.
-module(chat_pg_worker).
-behaviour(gen_server).
-behaviour(poolboy_worker).
-include("chat.hrl").
-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

start_link(Args) -> gen_server:start_link(?MODULE, Args, []).

init(_Args) ->
  process_flag(trap_exit, true),
  {ok, #{conn => undefined}}.

handle_call(get_conn, _From, #{conn := undefined} = S) ->
  case connect() of
    {ok, C} -> {reply, {ok, C}, S#{conn => C}};
    {error, Reason} -> {reply, {error, Reason}, S}
  end;
handle_call(get_conn, _From, #{conn := C} = S) ->
  {reply, {ok, C}, S}.

%% Caller crashed mid-use: drop the connection (it may be inside an open transaction).
handle_cast(reset, #{conn := C} = S) ->
  close(C),
  {noreply, S#{conn => undefined}};
handle_cast(_Msg, S) -> {noreply, S}.

handle_info({'EXIT', C, Reason}, #{conn := C} = S) ->
  ?LOG_WARNING(#{event => db_connection_lost, reason => Reason}),
  {noreply, S#{conn => undefined}};
handle_info(_Info, S) -> {noreply, S}.

terminate(_Reason, #{conn := C}) -> close(C).

connect() ->
  Opts = #{host => chat_config:get(db_host), port => chat_config:get(db_port),
           username => chat_config:get(db_user), password => chat_config:get(db_password),
           database => chat_config:get(db_name), timeout => 5000},
  case epgsql:connect(Opts) of
    {ok, C} -> {ok, C};
    {error, Reason} ->
      ?LOG_ERROR(#{event => db_connect_failed, reason => Reason}),  %% never log Opts: it holds the password
      {error, Reason}
  end.

close(undefined) ->
    ok;
close(C) ->
    try epgsql:close(C)
    catch
        _:_ -> ok
    end.
