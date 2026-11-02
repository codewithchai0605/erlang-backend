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
  Host = chat_config:get(db_host),
  Opts = maps:merge(#{host => Host, port => chat_config:get(db_port),
                      username => chat_config:get(db_user), password => chat_config:get(db_password),
                      database => chat_config:get(db_name), timeout => 5000},
                    tls_opts(chat_config:get(db_ssl), Host)),
  case epgsql:connect(Opts) of
    {ok, C} -> {ok, C};
    {error, Reason} ->
      ?LOG_ERROR(#{event => db_connect_failed, reason => Reason}),  %% never log Opts: it holds the password
      {error, Reason}
  end.

%% TLS to PostgreSQL (CHAT_DB_SSL):
%%   disable - plain TCP (local development, private networks)
%%   require - encrypted, server certificate NOT verified (libpq sslmode=require): stops passive snooping only
%%   verify  - encrypted AND the certificate chain and host name are checked against the OS trust store
%% SNI is always sent for host names: managed providers such as Neon use it to route the connection.
tls_opts(disable, _Host) -> #{};
tls_opts(require, Host) -> #{ssl => required, ssl_opts => [{verify, verify_none}, {server_name_indication, sni(Host)}]};
tls_opts(verify, Host) ->
  #{ssl => required,
    ssl_opts => [{verify, verify_peer}, {cacerts, public_key:cacerts_get()},
                 {server_name_indication, sni(Host)},
                 {customize_hostname_check, [{match_fun, public_key:pkix_verify_hostname_match_fun(https)}]}]}.

sni(Host) ->
  case inet:parse_address(Host) of
    {ok, _} -> disable;    %% TLS forbids IP addresses in SNI
    _ -> Host
  end.

close(undefined) ->
    ok;
close(C) ->
    try epgsql:close(C)
    catch
        _:_ -> ok
    end.
