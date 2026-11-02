# Changelog

## Milestones 5 + 6 (and first compile of 0-4)

### Fixes to existing code (found by compiling and testing for the first time)
- `backend/include/chat.hrl` was missing from the uploaded archive although ten modules include it. **Reconstructed** from how it is used (`?CONN_SCOPE`, `?DB_POOL`, `?PROTOCOL_VERSION`, `?CAPABILITIES`, logger include). Diff it against your local copy before overwriting.
- `chat_db:transaction/1` used `epgsql:with_transaction/2`, which turns every exception (including `throw({abort, _})`) into `{rollback, _}`. That made the idempotent-send race handler dead code since Milestone 4. Now `/3` with `reraise => true`; regression test `concurrent_duplicate_sends` fails without the fix.
- `chat_otp_SUITE` used `{ranch_listener_sup, _}` as the listener child id; Ranch 2.x uses `{ranch_embedded_sup, _}` (3 tests failed).
- `chat_config_tests` expected the pre-Render defaults (bind 127.0.0.1, port 8080) while the code had 0.0.0.0/10000. Secure defaults restored (loopback, 8080); Docker sets `CHAT_HTTP_BIND=0.0.0.0` and Render supplies `PORT`.
- A `typing` error reply dropped the caller's `request_id`.
- `chatSyncProvider` watched the whole auth state (a profile edit would have reconnected the socket); it now watches only the user id.
- `scripts/dev/sanity_check.py` mis-parsed `%` inside strings; replaced by a character scanner.

### Milestone 5: presence, typing, groups
Backend: `chat_presence`, `chat_task_sup`/`chat_task`, `chat_typing`, `chat_groups`; migration `0005`; protocol additions (new `oneof` variants, `MemberRole`); bounded history for late joiners; storage callbacks in `chat_repo`/`chat_repo_pg`; 13 new golden vectors; 20 new tests.
Client: presence and typing state, group create/add/remove/leave/rename in `ChatSync`, Drift schema v2 (`members.role`).

### Milestone 6: polish and hosting
Client: conversation list with search, avatars with presence dots, typing in subtitles; chat header with live status; group info and member management; new-group screen; settings (display name, theme, connection, sign out everywhere); desktop keyboard shortcuts; accessibility labels and live regions; loading/error/empty/"removed" states; first Flutter tests.
Hosting: `Dockerfile`, `docker/entrypoint.sh`, `docker-compose.yml`, `render.yaml`, `.dockerignore`, `.gitattributes`; `PORT`/`DATABASE_URL`/`CHAT_DB_SSL` support; pooler-safe migrations; `-name chat@127.0.0.1`.

### Files you must regenerate after pulling
`client/lib/core/protocol/gen/*` and `client/lib/core/db/app_database.g.dart` are stale: run `bash scripts/dev/regen-client.sh`.
