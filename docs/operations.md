# Operations

## 1. Toolchain

Erlang/OTP **27 or newer** (uses the built-in `json` module), rebar3, Flutter (stable; Dart 3.13+), `protoc` + Dart plugin (`dart pub global activate protoc_plugin`), PostgreSQL 13+ **or Docker**, Android SDK, and for Windows builds Visual Studio with *Desktop development with C++*. `bash scripts/dev/check-toolchain.sh` prints what you have.

You do **not** need Erlang, rebar3 or PostgreSQL installed to run the backend: Docker (section 5) provides all three.

### Tested tool versions

Backend (verified in the authoring sandbox): Erlang/OTP 29.1.2 (ERTS 17.1.1), rebar3 3.28.0, PostgreSQL 16, gpb 4.21.7 and 5.0.0, cowboy 2.20.0, cowlib 2.21.0, ranch 2.3.0, epgsql 4.8.0, poolboy 1.5.2, bcrypt 2.0.0, gun 2.2.0. Dart SDK 3.13.7 was used for a syntax check only. **Not verified anywhere yet:** Flutter, `flutter analyze`, `flutter test`, the Docker image build. Paste your own `check-toolchain.sh` output here once those pass.

## 2. What still needs your verification

The backend has real test evidence (see README). These items could not be exercised in the authoring sandbox:

1. **Docker image build** (`docker compose up --build`): the Dockerfile is lint-clean and the identical `rebar3 as prod release` was run natively, but `docker build` itself was not. The one thing the sandbox could not test is the `rebar3_gpb_plugin` step, because Hex was unreachable there; it is the same plugin your local builds already use.
2. **Flutter client**: regenerate (`gen-proto.sh`, `build_runner`), then `flutter analyze` and `flutter test`. The new screens were written against generated names (`ServerEnvelope_Body.presenceSnapshot`, `MemberRole.MEMBER_ROLE_OWNER`, ...) that exist only after regeneration. Expect a short fix-up if a package API moved.
3. `flutter test test/chat_sync_test.dart` needs the native SQLite library (on Windows put `sqlite3.dll` on PATH). If it cannot load, that single file fails to start; the other test files are independent.
4. `render.yaml` against Render's current Blueprint schema (the field names used are the long-standing ones: `runtime`, `dockerfilePath`, `healthCheckPath`, `envVars`, `generateValue`, `sync: false`).
5. Connecting to Neon itself. The TLS code path is proven against a local PostgreSQL that rejects plaintext, but Neon's pooler has not been contacted.

## 3. Configuration

All variables are documented in `.env.example` (single source of truth for `chat_config.erl`). Two hosting-friendly aliases exist so the same image works everywhere:

- `PORT` is used when `CHAT_HTTP_PORT` is not set (Render injects `PORT`).
- `CHAT_DATABASE_URL` (or `DATABASE_URL`) `postgresql://user:pass@host:5432/db?sslmode=require` fills in `CHAT_DB_HOST/PORT/NAME/USER/PASSWORD/SSL`. Explicit `CHAT_DB_*` variables win over the URL. `sslmode`: `disable|allow` = no TLS, `prefer|require` = TLS without certificate verification, `verify-ca|verify-full` = TLS with verification. Percent-encode special characters in the password (`@` is `%40`).
- `CHAT_DB_SSL=verify` is the strict setting (certificate chain and host name checked against the OS trust store, SNI sent). Prefer it once your provider works with `require`.

Empty variables count as unset. Bad values stop startup with the variable **names** listed, never the values.

Never commit `.env`, and never bake it into an image (`.dockerignore` and `.gitignore` both exclude it).

## 4. Database

Docker: `docker compose up -d postgres` (bound to 127.0.0.1). Or any PostgreSQL 13+ matching `CHAT_DB_*`. Migrations run at startup (`CHAT_RUN_MIGRATIONS=true`) and are safe when two instances start at once, including through a transaction-pooling proxy such as Neon's `-pooler` endpoint (the lock is transaction-scoped).

## 5. Run on Windows with Docker (recommended)

1. Install **Docker Desktop** (WSL 2 backend) and start it.
2. In the repository root (PowerShell or Git Bash):
   ```
   docker compose up --build
   ```
   First build: a few minutes (it downloads the Erlang image and compiles dependencies). Later builds reuse cached layers; only changed source recompiles.
3. Check: `curl.exe http://localhost:8080/healthz` and `/readyz` (use `curl.exe`, PowerShell's `curl` is a different command).
4. Follow logs: `docker compose logs -f backend`. Stop: `Ctrl+C`, or `docker compose down` (keeps data) / `docker compose down -v` (wipes data).

Compose always talks to its **own** PostgreSQL, whatever `CHAT_DB_*` you have in `.env` (e.g. a Neon URL). Only the database alone: `docker compose up -d postgres`.

Plain `docker run`:
```
docker build -t chat-backend .
docker run --rm -p 8080:8080 -e CHAT_DATABASE_URL="postgresql://chat:pw@host.docker.internal:5432/chat_dev" chat-backend
```
(`host.docker.internal` reaches PostgreSQL running on the Windows host.)

What the image does: two stages on the same Debian base (a release links OpenSSL/ncurses dynamically, so build and runtime must match); runs as a non-root user from a read-only directory; `tini` as init; health check on `/healthz`; the entrypoint generates a random Erlang cookie if you did not set one; Windows CRLF line endings in the entrypoint are stripped at build time. Build another Erlang version with `--build-arg OTP_VERSION=28` (minimum 27).

## 6. Deploy to Render (+ Neon)

1. Push the repository to GitHub (check that `.env` is **not** in it).
2. Create a database (e.g. Neon) and copy its connection string.
3. Render dashboard -> **New -> Blueprint** -> select the repository. Render reads `render.yaml`, builds the Dockerfile, and asks you for `CHAT_DATABASE_URL` (paste the string; it is stored as a secret and never committed).
4. When it is live: `https://<name>.onrender.com/readyz` should answer `{"status":"ready"}`.
5. Build the client against it: `flutter run -d windows --dart-define=CHAT_BASE_URL=https://<name>.onrender.com` (the app uses `wss://` automatically for `https://`).

Things to know:
- **Run exactly one instance.** Rate limits, presence and WebSocket fan-out are in-memory per node (documented limitation of the single-node design). Do not scale out.
- Free web services sleep after ~15 minutes idle: the first request afterwards takes tens of seconds, and open WebSockets are dropped. The client reconnects with backoff and re-syncs, so nothing is lost; users see "Offline/Connecting" briefly. A paid instance avoids sleeping.
- Render terminates TLS. Inside the container the app speaks plain HTTP on `$PORT`.
- Use a small pool on free databases: `CHAT_DB_POOL_SIZE=5` (preset in `render.yaml`).
- To use a Render-managed Postgres instead, uncomment the `databases:` block and the `fromDatabase` entry in `render.yaml`.

## 7. Run the backend natively (without Docker)

```
cd backend
rebar3 compile            # also runs the gpb plugin (generates src/gen/chat_pb.erl)
rebar3 shell              # development shell with the app started
curl localhost:8080/healthz       # liveness
curl localhost:8080/readyz        # readiness (checks the database)
curl localhost:8080/metrics       # Prometheus text, loopback peers only
```
Export the variables from `.env` first (`set -a; . ./.env; set +a` in bash). Release: `rebar3 as prod release`, then `_build/prod/rel/chat/bin/chat foreground` (needs `CHAT_NODE_COOKIE`). The node is named `chat@127.0.0.1`; distribution and epmd are loopback-only. `bin/chat ping` answers `pong` when the cookie matches.

Logs are single-line events on stdout. Graceful shutdown (SIGTERM / `docker stop`) first closes every WebSocket with 1001 and records last-seen times.

## 8. Run the client

```
cd client
flutter pub get
bash ../scripts/dev/gen-proto.sh                               # Dart protobuf code from proto/chat/v1/chat.proto
dart run build_runner build --delete-conflicting-outputs       # Drift code (app_database.g.dart)
flutter run -d windows --dart-define=CHAT_BASE_URL=http://localhost:8080
flutter run -d <android-device> --dart-define=CHAT_BASE_URL=http://<your-LAN-ip>:8080
```
Rerun **both** generation commands whenever `chat.proto` or `app_database.dart` changes (Milestone 5 changed both; Milestone 6 added the `shared_preferences` dependency, so run `flutter pub get` too).

Android emulator reaches the host at `http://10.0.2.2:8080` (the default). Plain `http://` needs `android:usesCleartextTraffic="true"` in the **debug/profile** manifest only; release builds must use HTTPS/WSS. For a phone on your LAN, publish the compose port (it is by default) and allow it in Windows Firewall (development only).

Desktop keyboard shortcuts: `Ctrl+N` new chat, `Ctrl+Shift+N` new group, `Ctrl+,` settings, `Esc` close the open chat, `Enter` send, `Shift+Enter` newline.

## 9. Tests

```
cd backend
rebar3 eunit                                   # 52: config, validation, protocol + golden vectors, rate limiter
rebar3 ct --suite test/chat_otp_SUITE          # 7: supervision behaviour, no database needed
CHAT_TEST_DB_NAME=chat_test CHAT_TEST_DB_USER=chat CHAT_TEST_DB_PASSWORD=change-me rebar3 ct --suite test/chat_e2e_SUITE   # 13
# optional: CHAT_TEST_DB_HOST=... CHAT_TEST_DB_SSL=require to test over TLS
python3 ../scripts/dev/make_golden_vectors.py  # needs: pip install grpcio-tools protobuf
cd ../client
flutter test
```
`chat_e2e_SUITE` uses a **disposable** database (it creates users freely). It covers register/login/refresh, refresh-reuse revocation, hello required, text frames rejected, bad token, chat with push, idempotent resend, concurrent duplicate sends (a race regression), receipts, offline sync, history paging, non-member denial, typing relay, presence (incl. reconnect grace), group lifecycle (create, add, rename, remove, leave, ownership transfer, history boundary), group limits, and direct chats not being modifiable.

## 10. Troubleshooting

- *App refuses to start with `invalid_config`*: the log lists the offending variable names (never values).
- *`db_unavailable` / `/readyz` 503*: PostgreSQL not reachable with the `CHAT_DB_*` settings, or TLS mismatch (`reason: invalid_authorization_specification` usually means the server insists on TLS: set `CHAT_DB_SSL=require`). Workers connect lazily and retry on the next request.
- *Docker: container exits at once*: `docker compose logs backend`. `/bin/sh^M` or `exec format error` means CRLF line endings: the Dockerfile strips them from the entrypoint, so this points at a stale image; rebuild with `--no-cache`.
- *Docker: port already in use*: change the left side of `"8080:8080"` in `docker-compose.yml`.
- *Client stuck on "Connecting..."*: wrong `CHAT_BASE_URL`, backend bound to loopback while the device is remote, or cleartext traffic blocked on Android.
- *Client signs out repeatedly*: refresh token reuse detected (two app instances sharing one account session, or a retried refresh); sign in again.
- *Dart errors about missing `chat.pb.dart` / `app_database.g.dart`, or "role"/"presence" not defined*: run the two generation commands in section 8.
- *Render: deploy succeeds but `/readyz` is 503*: wrong `CHAT_DATABASE_URL` or the database blocks Render's IPs.

## 11. Backup / restore

Back up with `pg_dump` (custom format) and restore with `pg_restore`; the schema is recreated by migrations on an empty database.
