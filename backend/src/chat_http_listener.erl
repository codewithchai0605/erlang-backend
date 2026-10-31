%% @doc The Cowboy listener, embedded as a supervisor child via ranch:child_spec/5 (cowboy:start_clear
%% would start it outside our tree). TLS is terminated by a reverse proxy in front (docs/security.md);
%% by default this listens on loopback only.
-module(chat_http_listener).
-export([child_spec/0]).

child_spec() ->
  Dispatch = cowboy_router:compile([{'_', routes()}]),
  TransOpts = #{socket_opts => [{ip, chat_config:get(http_bind)}, {port, chat_config:get(http_port)}],
                max_connections => chat_config:get(max_connections)},
  ProtoOpts = #{env => #{dispatch => Dispatch}, request_timeout => 15000, idle_timeout => 120000},
  ranch:child_spec(chat_http, ranch_tcp, TransOpts, cowboy_clear, ProtoOpts).

routes() ->
  [{"/healthz", chat_http_handler, health},
   {"/readyz", chat_http_handler, ready},
   {"/metrics", chat_http_handler, metrics},
   {"/api/v1/auth/register", chat_http_handler, register},
   {"/api/v1/auth/login", chat_http_handler, login},
   {"/api/v1/auth/refresh", chat_http_handler, refresh},
   {"/api/v1/auth/logout", chat_http_handler, logout},
   {"/api/v1/auth/logout-all", chat_http_handler, logout_all},
   {"/api/v1/me", chat_http_handler, me},
   {"/api/v1/users/lookup", chat_http_handler, user_lookup},
   {"/ws", chat_ws_handler, #{}}].
