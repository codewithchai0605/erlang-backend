%% Shared macros for the chat backend. Records live next to the module that owns them; only things used by
%% several modules belong here.
-ifndef(CHAT_HRL).
-define(CHAT_HRL, true).

%% ?LOG_INFO/?LOG_WARNING/?LOG_ERROR ... (structured logging with maps, see docs/operations.md)
-include_lib("kernel/include/logger.hrl").

%% Wire protocol version negotiated in Hello/HelloAck. Bump only for INCOMPATIBLE changes; additive
%% protobuf changes (new fields, new oneof variants) keep version 1 and are advertised via capabilities.
-define(PROTOCOL_VERSION, 1).
-define(CAPABILITIES, [<<"history">>, <<"receipts">>, <<"typing">>, <<"presence">>, <<"groups">>]).

%% OTP `pg` scope holding every authenticated WebSocket connection (group key {user, UserId}).
-define(CONN_SCOPE, chat_conns).
%% Registered name of the poolboy pool that owns the PostgreSQL connections.
-define(DB_POOL, chat_db_pool).
-endif.
