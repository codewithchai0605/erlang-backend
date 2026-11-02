# Chat App (Erlang/OTP + Flutter)

A learning-focused, production-minded chat application. Backend: Erlang/OTP (rebar3, Cowboy, PostgreSQL). Clients: one Flutter codebase for Android and Windows. Real-time traffic is binary Protobuf over WebSocket; ordinary HTTP endpoints (register/login/profile) use JSON. The specification is [AGENT.md](AGENT.md).

## Status

Milestones 0-6 are implemented. What has been **machine-verified** and what has **not** is spelled out here, because a green badge you cannot trust is worse than none:

| Area | Verified how | Result |
|---|---|---|
| Backend compile | rebar3 on Erlang/OTP 29.1.2, locked dependency versions | clean, no warnings |
| Backend unit tests | EUnit (config, validation, protocol, golden vectors, rate limiter) | 52 passing |
| Backend integration | Common Test against a real PostgreSQL 16: auth, chat, receipts, sync, groups, typing, presence, races | 13 passing, repeated runs stable |
| Backend supervision | Common Test: restart strategies, presence rebuild, dynamic supervisor | 7 passing |
| Protobuf schema | the real `protoc` compiles it; golden vectors cross-checked (hand encoder = protoc runtime = Erlang gpb) | OK, gpb 4.21.7 and 5.0.0 |
| DB over TLS | server configured to reject plaintext; `disable` rejected, `require` works, `verify` refuses an untrusted cert | OK |
| Production release | `rebar3 as prod release`, run as non-root from a read-only dir with only `PORT` + `DATABASE_URL` | boots, migrates, `/healthz` `/readyz` OK, SIGTERM stops it |
| Dockerfile | `hadolint` clean; **not built** (no Docker in the authoring sandbox) | build it once on your PC |
| `docker-compose.yml`, `render.yaml` | parsed as YAML; **not run** | run them once |
| Flutter client | Dart syntax check of all 41 source and test files; **not compiled, not run** (no Flutter SDK, no pub.dev access) | needs your `flutter analyze` + `flutter test` |

| Milestone | Scope | State |
|---|---|---|
| 0 Repository, toolchain | layout, config, docs skeleton | done |
| 1 OTP foundation + DB | supervision tree, config, pool, migrations, health/metrics | done, tested |
| 2 Auth | register/login/refresh/logout, sessions, Flutter auth UI | done; backend tested, client untested |
| 3 Real-time chat | direct conversations, WebSocket send/receive, chat UI | done; backend tested, client untested |
| 4 Reliability | idempotent sends, reconnect + sync, history paging, receipts, outbox | done; backend tested, client untested |
| 5 Presence, typing, groups | online/last-seen, typing indicators, group chats with owner/member roles | done; backend tested, client untested |
| 6 Polish | settings/profile, theme, search, keyboard shortcuts, accessibility, empty/error/offline states, Docker + Render | done; client untested |
| 7 Advanced learning | - | not started |

## Quick start (Windows, Docker Desktop)

```powershell
copy .env.example .env        # optional: compose works without it
docker compose up --build     # PostgreSQL + backend; first build takes a few minutes
curl.exe http://localhost:8080/readyz
```

Then the app (after the one-time generation steps in [docs/operations.md](docs/operations.md) section 7):

```powershell
cd client
flutter pub get
bash ../scripts/dev/gen-proto.sh            # Git Bash; regenerates the Dart protobuf code
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows --dart-define=CHAT_BASE_URL=http://localhost:8080
```

**After pulling Milestone 5/6 you MUST regenerate** (`bash scripts/dev/regen-client.sh` does `pub get` + both commands above): the schema gained messages and the local database gained a column, and the committed generated Dart files predate both.

Deploying to Render + Neon: [docs/operations.md](docs/operations.md) section 6.

## Documentation

- docs/operations.md - setup on Windows, Docker, Render/Neon, tests, troubleshooting
- docs/architecture.md - components, supervision tree, message flows
- docs/protocol.md - Protobuf schema, WebSocket rules, delivery semantics
- docs/database.md - schema and migrations
- docs/security.md - what is protected, what is not
- docs/learning-guide.md - Erlang/OTP concepts explained with this code
- docs/decisions/ - architecture decision records
