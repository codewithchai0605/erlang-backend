# Operations

## 1. Toolchain (install and verify yourself)

Erlang/OTP **27 or newer** (uses the built-in `json` module), rebar3, Flutter (stable, includes Dart 3.4+), `protoc` + Dart plugin (`dart pub global activate protoc_plugin`), PostgreSQL 13+ (or Docker), Android SDK, and for Windows builds Visual Studio with *Desktop development with C++* (flutter_secure_storage on Windows may also need the ATL component). Run `bash scripts/dev/check-toolchain.sh` and record the output below.

### Tested tool versions

None recorded yet - nothing has been compiled. Paste `check-toolchain.sh` output here after your first successful build.

## 2. First-compile checklist (things written from memory, to VERIFY)

These are the places where this code calls third-party APIs that could not be checked offline. If the first compile or test run fails, look here first.

Backend:
1. `rebar.config`: dependency requirements (`~>` ranges), the `rebar3_gpb_plugin` option names, and that `{src_dirs, ["src","src/gen"]}` makes rebar3 compile the generated `src/gen/chat_pb.erl`. Alternative if the hook misbehaves: `rebar3 protobuf compile` once, or generate with gpb's `protoc-erl` into `src/gen`.
2. gpb with `maps`: oneofs must decode as `body => {Variant, Value}` and enum values as atoms like `'ERROR_CODE_INVALID_ARGUMENT'`; message names must be `'ClientEnvelope'` etc. (no package prefix). Adjust `chat_protocol`/`chat_ws_handler` if your gpb version differs. `chat_protocol_tests` exercises exactly this.
3. `bcrypt` (`chat_password.erl`): `gen_salt/0` and `hashpw/2` signatures and return values (binary vs string).
4. `epgsql`: `connect/1` map options; `equery` result shapes (`{ok, Cols, Rows}` / `{ok, Count}` / `{ok, Count, Cols, Rows}`); `with_transaction/2` committing on normal return and rolling back + re-raising on exceptions (`chat_db:transaction/1` relies on this); `uuid` parameters accepted as text binaries; `bytea` params as binaries; `null` for SQL NULL.
5. `poolboy`: `child_spec/3`, `transaction/3`, the `poolboy_worker` behaviour.
6. `ranch:child_spec/5` with `cowboy_clear` and the option maps in `chat_http_listener.erl`; Cowboy `read_body` options and `match_qs/2`.
7. `pg:start_link/1`, `get_members/2`, `get_local_members/2`, `which_groups/1` (OTP 23+); `base64:encode/2` options and `binary:encode_hex/2` (OTP 26+); `json:encode/1`, `json:decode/1` (OTP 27+).
8. `vm.args.src` / `sys_config` handling in the relx release (`CHAT_NODE_COOKIE` must be set).

Client:
1. Generated Dart names: `ServerEnvelope_Body.helloAck`, `.newMessage`, `.conversationList`, `ClientEnvelope.syncRequest`, `Int64` fields, enum constants like `ErrorCode.ERROR_CODE_INTERNAL`, and that `chat.pb.dart` re-exports `chat.pbenum.dart`. The `protobuf` package version must match the `protoc_plugin` that generated the code.
2. Drift: `dart run build_runner build` must generate `app_database.g.dart`; `driftDatabase(name:)` from drift_flutter; `NativeDatabase.memory()` in tests needs a SQLite library on the host (on Windows put `sqlite3.dll` on PATH).
3. `web_socket_channel` 3.x: `IOWebSocketChannel.connect(..., pingInterval:, connectTimeout:)`, `.ready`, `.closeCode`.
4. `go_router` 14 redirect/`refreshListenable` usage; Riverpod 2.x (`Notifier`, `overrideWith`).
5. Material 3 names (`surfaceContainerHighest`, `Badge`) need a recent stable Flutter.
After the code compiles, add `warnings_as_errors` to `erl_opts` and run `flutter analyze` / `rebar3 dialyzer`.

## 3. Configuration

All variables are documented in `.env.example` (single source of truth for `chat_config.erl`). `cp .env.example .env`, edit, and export into your shell: `set -a; . ./.env; set +a`. Never commit `.env`.

## 4. Database

`docker compose up -d postgres` (bound to 127.0.0.1) or a native PostgreSQL with a database and user matching `CHAT_DB_*`. Migrations run at startup (`CHAT_RUN_MIGRATIONS=true`). Migration failures abort startup with the failing version in the log.

## 5. Run the backend

```
cd backend
rebar3 compile            # also runs the gpb plugin (generates src/gen/chat_pb.erl)
rebar3 shell              # development shell with the app started
curl localhost:8080/healthz       # liveness
curl localhost:8080/readyz        # readiness (checks the database)
curl localhost:8080/metrics       # Prometheus text, loopback peers only
```
Release: `rebar3 as prod release`, then `_build/prod/rel/chat/bin/chat foreground` (needs `CHAT_NODE_COOKIE`).

Logs are single-line events on stdout (`event: ws_connected`, ...). Graceful shutdown (`bin/chat stop`) first tells every WebSocket to close with 1001.

## 6. Run the backend in Docker

Build from the repository root so the Docker build can access both `backend/` and `proto/`:

```
docker build -f backend/Dockerfile -t chat-backend .
docker run --rm -p 10000:10000 --env-file .env chat-backend
```

The image listens on `0.0.0.0:10000`. Provide the required `CHAT_DB_NAME`, `CHAT_DB_USER`, `CHAT_DB_PASSWORD`, and `CHAT_NODE_COOKIE` values at runtime, and configure `CHAT_DB_HOST` to a PostgreSQL host reachable from the container.

## 7. Run the client

```
cd client
flutter create --platforms=android,windows --project-name chat_client .   # generates android/ and windows/ (keeps lib/)
flutter pub get
bash ../scripts/dev/gen-proto.sh
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows --dart-define=CHAT_BASE_URL=http://localhost:8080
flutter run -d <android-device> --dart-define=CHAT_BASE_URL=http://<your-LAN-ip>:8080
```
Android emulator reaches the host at `http://10.0.2.2:8080` (the default). Plain `http://` needs `android:usesCleartextTraffic="true"` in the **debug/profile** manifest only; release builds must use HTTPS/WSS and need `<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml` if `flutter create` did not add it. For a device on your LAN set `CHAT_HTTP_BIND=0.0.0.0` and firewall appropriately (development only).

## 8. Tests

```
cd backend
rebar3 eunit                       # config, validation, protocol + golden vectors, rate limiter
rebar3 ct --suite test/chat_otp_SUITE      # supervision behaviour, no database needed
CHAT_TEST_DB_NAME=chat_test CHAT_TEST_DB_USER=chat CHAT_TEST_DB_PASSWORD=change-me rebar3 ct --suite test/chat_e2e_SUITE
cd ../client
flutter test                       # needs generated protocol + drift code first
python3 ../scripts/dev/sanity_check.py     # bracket-balance check (works without any toolchain)
```
`chat_e2e_SUITE` covers: register/login/refresh, refresh-reuse revocation, hello required, text frames rejected, bad token, two users chatting with push, idempotent resend, delivery receipts, offline sync, backward history paging, non-member denial.

## 9. Troubleshooting

- *App refuses to start with `invalid_config`*: the log lists the offending variable names (never values).
- *`db_unavailable` / `/readyz` 503*: PostgreSQL not reachable with the `CHAT_DB_*` settings; workers connect lazily and retry on the next request.
- *Client stuck on "Connecting..."*: wrong `CHAT_BASE_URL`, backend bound to loopback while the device is remote, or cleartext traffic blocked on Android.
- *Client signs out repeatedly*: refresh token reuse detected (two app instances sharing one account session, or a retried refresh); sign in again.
- *Dart errors about missing `chat.pb.dart` or `app_database.g.dart`*: run the generation steps in section 6.

## 10. Backup / restore, deployment

Back up with `pg_dump` (plain custom format) and restore with `pg_restore`; the schema is recreated by migrations on an empty database. A deployment guide (reverse proxy with TLS, systemd unit, release upgrades) is part of Milestone 6.
