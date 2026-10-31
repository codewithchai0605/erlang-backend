# Chat App (Erlang/OTP + Flutter)

A learning-focused, production-minded chat application. Backend: Erlang/OTP (rebar3, Cowboy, PostgreSQL). Clients: one Flutter codebase for Android and Windows. Real-time traffic is binary Protobuf over WebSocket; ordinary HTTP endpoints (register/login/profile) use JSON. The specification is [AGENT.md](AGENT.md).

## Status - READ THIS FIRST

Milestones 0-4 are **written but have never been compiled or run**. The authoring sandbox had no Erlang, rebar3, Flutter, Dart, protoc, PostgreSQL or network access. Only these things were machine-checked: the protobuf golden vectors (against the official Python protobuf runtime) and a bracket-balance check of every source file. Expect a first-compile fix-up session; [docs/operations.md](docs/operations.md) lists exactly which third-party API usages to verify first.

| Milestone | Scope | State |
|---|---|---|
| 0 Repository, toolchain | layout, config, docs skeleton | done |
| 1 OTP foundation + DB | supervision tree, config, pool, migrations, health/metrics | code written, untested |
| 2 Auth | register/login/refresh/logout, sessions, Flutter auth UI | code written, untested |
| 3 Real-time chat | direct conversations, send/receive over WebSocket, Flutter chat UI | code written, untested |
| 4 Reliability | idempotent sends, reconnect + sync, history paging, receipts, outbox | code written, untested |
| 5 Presence, typing, groups | - | not started |
| 6 Polish | - | not started |
| 7 Advanced learning | - | not started |

## Quick start

See docs/operations.md. In short: install the toolchain, `cp .env.example .env`, start PostgreSQL (`docker compose up -d postgres`), `cd backend && rebar3 compile`, run the release or `rebar3 shell`, then `cd client && flutter create --platforms=android,windows . && flutter pub get && bash ../scripts/dev/gen-proto.sh && dart run build_runner build && flutter run`.

## Documentation

- docs/architecture.md - components, supervision tree, message flows
- docs/protocol.md - Protobuf schema, WebSocket rules, delivery semantics
- docs/database.md - schema and migrations
- docs/security.md - what is protected, what is not
- docs/operations.md - setup, run, test, first-compile checklist
- docs/learning-guide.md - Erlang/OTP concepts explained with this code
- docs/decisions/ - architecture decision records
