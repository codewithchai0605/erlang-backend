# Agent Instructions --- Erlang + Flutter Chat Application

You are the implementation agent for a learning-focused,
production-minded chat application. Build the backend in **Erlang/OTP**
and the clients in **Flutter**, targeting **Android and Windows**.

The project is intended both to become a useful chat application and to
teach its owner how Erlang/OTP, distributed systems, networking, Flutter
architecture, and reliable messaging work. Do not hide complexity behind
unexplained abstractions: implement in small stages and document the
reasoning.

## 1. Core goals

Build a maintainable chat application with:

- **Binary Protobuf messaging over WebSocket.** Do not use JSON for real-time chat events or message payloads. JSON is permitted for ordinary HTTP endpoints only if documented.

-   Account registration, login, logout, and session refresh.
-   One-to-one conversations and group conversations.
-   Real-time text messaging.
-   Message history and pagination.
-   Message delivery/read state, at least for the current
    device/session.
-   Online/offline presence and last-seen information.
-   Typing indicators.
-   Reconnection and synchronization after temporary network loss.
-   Basic profile management and avatar support.
-   Local client cache and a sensible offline/poor-network experience.
-   Responsive, accessible UI on Android phones, tablets, and Windows
    desktop.
-   Automated tests, database migrations, operational logging, and clear
    documentation.

Keep the first release deliberately small. Implement a working vertical
slice before adding optional features. Do not claim WhatsApp feature
parity.

## 2. Technology choices

### Backend

Use:

-   **Erlang/OTP** as the backend language and runtime.
-   **rebar3** for dependency management, compilation, testing,
    releases, and shell tasks.
-   **OTP applications, supervisors, and behaviours** as the foundation
    of the architecture.
-   **Cowboy** for HTTP and WebSocket endpoints. Use its current stable
    release compatible with the selected OTP version.
-   **PostgreSQL** as the default server database.
-   An Erlang PostgreSQL driver such as **epgsql** (or another actively
    maintained Erlang-native driver after evaluating compatibility).
-   A migration tool compatible with the selected database driver, or a
    small, well-tested migration runner if a suitable tool is not
    available.
-   A maintained password-hashing library supporting Argon2id or bcrypt.
    Never store plaintext passwords and never invent a custom password
    hash.
-   A well-maintained JWT or opaque-token implementation if tokens are
    used. Prefer short-lived access tokens and rotating refresh tokens;
    store refresh-token hashes server-side.
-   **Protocol Buffers (Protobuf) for real-time chat messages.** WebSocket application messages must use binary WebSocket messages containing Protobuf-encoded payloads. Do not use JSON for chat events or message payloads.
-   Keep `.proto` schemas as the source of truth and generate code for both Erlang and Dart/Flutter. Evaluate a maintained Erlang Protobuf implementation such as `gpb` and the Dart `protobuf` tooling; verify current OTP/Dart compatibility before selecting versions.
-   Keep transport, Protobuf encoding/decoding, and domain logic in separate modules. Do not hand-maintain generated serialization code.
-   HTTP endpoints used for registration/login and ordinary REST operations may use JSON unless there is a strong reason to make those binary too. Clearly document this distinction. Real-time messaging itself must be binary.

Do not add a dependency just because it is popular. Check its
maintenance status, OTP compatibility, security posture, licence, and
API documentation before adopting it. Record the selected versions and
rationale in the documentation and lock dependencies through rebar3.

### Database modes

-   PostgreSQL is the normal development and production server database.
-   Also provide an optional **SQLite local-development mode** if it can
    be implemented cleanly with a maintained Erlang SQLite driver.
-   Keep database operations behind a repository/storage behaviour so
    the chat domain does not depend directly on PostgreSQL or SQLite
    APIs.
-   Do not silently use SQLite in production.
-   If the SQLite adapter would substantially complicate the first
    milestone, finish PostgreSQL first, then add SQLite as a separate
    documented milestone. Do not weaken the PostgreSQL implementation to
    force both adapters into the initial release.

### Flutter clients

Use one Flutter codebase for:

-   Android
-   Windows desktop

Choose maintained packages after checking their current compatibility. A
reasonable starting set to evaluate:

-   `flutter_riverpod` for state management.
-   `go_router` for navigation.
-   `dio` for HTTP.
-   `web_socket_channel` for WebSocket communication, or a suitable
    maintained alternative.
-   `flutter_secure_storage` for credentials/tokens, using
    platform-appropriate secure storage.
-   `drift` with SQLite for local message/cache storage.
-   `connectivity_plus` for connectivity hints (do not treat
    connectivity status as proof that the server is reachable).
-   `image_picker` for image selection where supported.
-   `freezed` and `json_serializable` for immutable models and JSON
    serialization, if useful.

Verify Windows support for every chosen package. Do not assume an
Android plugin works on Windows. Document alternatives where a feature
is platform-specific.

## 3. Repository layout

Use a clear monorepo layout similar to:

``` text
chat-app/
├── AGENT.md
├── README.md
├── docs/
│   ├── architecture.md
│   ├── learning-guide.md
│   ├── protocol.md
│   ├── database.md
│   ├── security.md
│   ├── operations.md
│   └── decisions/
├── backend/
│   ├── rebar.config
│   ├── rebar.lock
│   ├── config/
│   ├── src/
│   ├── include/
│   ├── priv/
│   │   └── migrations/
│   └── test/
├── client/
│   ├── pubspec.yaml
│   ├── lib/
│   ├── test/
│   └── integration_test/
├── scripts/
│   ├── dev/
│   └── db/
└── .env.example
```

Adapt this layout when there is a concrete reason, and document any
change. Never commit secrets, real user data, local database files,
build output, or credentials.

## 4. Erlang/OTP architecture and learning requirements

Use OTP intentionally. The owner should be able to understand why each
process exists.

Start with a supervision tree along these lines (adjust as the
application develops):

``` text
chat_sup (one_for_one)
├── chat_config
├── chat_db_pool
├── chat_presence_sup
├── chat_session_sup
├── chat_message_dispatcher
└── chat_http_listener
```

Important design rules:

1.  Use an OTP application callback and a top-level supervisor.
2.  Use `gen_server` only for stateful services that benefit from
    serialized message handling. Do not create a `gen_server` for every
    ordinary function.
3.  Use `DynamicSupervisor` for dynamically created session/connection
    workers where appropriate.
4.  Use monitors and links deliberately. Explain which failures should
    propagate and which should be isolated.
5.  Define restart strategies and restart intensity intentionally. A
    supervisor restart is not a substitute for durable state.
6.  Keep database transactions and durable state in PostgreSQL, not only
    in process memory.
7.  Treat process mailboxes as queues: consider message volume,
    backpressure, timeouts, and overload behaviour.
8.  Avoid one global process becoming a bottleneck. Partition or shard
    state only when measurements justify it.
9.  Do not assume a process-per-user or process-per-connection design is
    automatically scalable. Benchmark it.
10. Handle graceful shutdown and application termination.
11. Use structured logging and meaningful error reasons. Do not swallow
    errors silently.
12. Explain the difference between an Erlang process, an
    operating-system process, a scheduler, and a native thread in the
    learning documentation.

### Required Erlang topics to demonstrate

Add focused examples and explanations for:

-   OTP application startup.
-   Supervisor trees and restart strategies.
-   `gen_server` callbacks and message handling.
-   `DynamicSupervisor` for connection/session workers.
-   Links, monitors, and process exit signals.
-   Erlang message passing and mailbox behaviour.
-   Pattern matching and tagged tuples.
-   Records/maps and data validation.
-   Error handling and the "let it crash" philosophy, including when
    *not* to crash.
-   ETS only where it has a clear use; explain its ownership and
    lifecycle.
-   Configuration and secrets.
-   EUnit and Common Test.
-   Releases and runtime configuration.
-   Distributed Erlang as a learning topic, but do not expose the Erlang
    distribution port publicly or enable unrestricted remote shell
    access.

Do not introduce distributed Erlang in the first working release. First
make a single-node server correct. Later document a safe cluster design
and the security implications of Erlang distribution (including node
cookies, network isolation, and version compatibility).

## 5. Backend boundaries

Separate the backend into understandable modules. Suggested
responsibilities:

-   `chat_auth`: registration, login, token refresh, logout.
-   `chat_users`: profile and user lookup.
-   `chat_conversations`: direct and group conversation membership.
-   `chat_messages`: message validation, persistence, history.
-   `chat_delivery`: delivery acknowledgements and retry state.
-   `chat_presence`: online status and last-seen.
-   `chat_typing`: ephemeral typing events.
-   `chat_ws_handler`: WebSocket lifecycle and frame handling.
-   `chat_http_handler`: HTTP request/response handling.
-   `chat_protocol`: Protobuf message types, protocol version/capabilities, semantic validation, and event dispatch.
-   `proto/`: canonical `.proto` schemas shared by backend and Flutter client (at the repository root or another clearly documented shared location).
-   `chat_repo`: storage behaviour and repository boundary.
-   `chat_repo_pg`: PostgreSQL adapter.
-   `chat_repo_sqlite`: optional local SQLite adapter.
-   `chat_config`: validated runtime configuration.

Keep transport handlers thin. They should parse and validate input,
authenticate, call domain services, and encode responses. Business rules
must not be buried in Cowboy callbacks.

## 6. Initial API and real-time binary protocol

Document the protocol before implementing features. **Real-time chat traffic must use binary WebSocket messages encoded with Protocol Buffers (Protobuf), not JSON.** Do not silently fall back to JSON for chat events.

Use `.proto` files as the canonical schema. Generate Erlang and Dart code from the same schemas. Keep generated files separate from hand-written domain code and document the exact code-generation commands.

Start with a versioned envelope. This is an illustrative starting schema; refine it during implementation:

```proto
syntax = "proto3";

package chat.v1;

message ClientEnvelope {
  string request_id = 1;
  oneof body {
    SendMessage send_message = 10;
    TypingEvent typing = 11;
    ReadReceipt read_receipt = 12;
    SyncRequest sync = 13;
  }
}

message SendMessage {
  string conversation_id = 1;
  string client_message_id = 2;
  string text = 3;
}

message TypingEvent {
  string conversation_id = 1;
  bool is_typing = 2;
}

message ReadReceipt {
  string conversation_id = 1;
  string message_id = 2;
}

message SyncRequest {
  string conversation_id = 1;
  string after_cursor = 2;
}

message ServerEnvelope {
  string request_id = 1;
  oneof body {
    MessageAccepted accepted = 10;
    NewMessage new_message = 11;
    ProtocolError error = 12;
  }
}

message MessageAccepted {
  string message_id = 1;
  string client_message_id = 2;
  string server_cursor = 3;
}

message NewMessage {
  string message_id = 1;
  string conversation_id = 2;
  string sender_id = 3;
  string text = 4;
  int64 created_at_unix_ms = 5;
}

message ProtocolError {
  string code = 1;
  string message = 2;
}
```

The schema is an initial example, not a final contract. Design event names, field numbers, IDs, timestamp representation, error codes, and compatibility rules deliberately.

Requirements:

- Use binary WebSocket messages for Protobuf payloads. Reject or explicitly handle unexpected text WebSocket messages.
- Define a stable outer envelope and use `oneof` (or an equally clear tagged-union design) for event variants.
- Keep field numbers stable. Never reuse a removed field number; reserve removed numbers and names.
- Add fields compatibly. Document which changes are backward/forward compatible.
- Include a protocol/application version or capability-negotiation strategy. Protobuf itself does not provide version negotiation.
- Generate both language bindings from the same `.proto` files and add a test/CI check that generated code is up to date.
- Test Erlang-to-Dart and Dart-to-Erlang encode/decode compatibility using shared golden test vectors.
- Validate semantic constraints after decoding: identifiers, text limits, membership, authorization, and supported event type.
- Set maximum WebSocket message sizes and rate limits.
- Use stable client-generated message IDs/idempotency keys so retries do not create duplicates.
- Distinguish server acceptance, recipient delivery, and read receipts.
- Do not promise exactly-once network delivery. Explain at-least-once delivery plus idempotent processing where appropriate.
- Support reconnect and history synchronization using a cursor or sequence.
- Handle unknown Protobuf fields according to compatibility rules; unsupported event variants should produce a documented protocol error where possible.
- Avoid logging message bodies, passwords, tokens, or encryption secrets.

Do not invent a custom binary wire encoding in the first milestone. Protobuf is the binary serialization format for the first version. Explain Protobuf field tags, wire types, varints, and length-delimited fields in the learning documentation. Also explain that WebSocket already provides message boundaries, so the application does not need to add the four-byte TCP length prefix from the earlier TCP exercise inside each WebSocket message.

## 7. Basic authentication and security

Implement:

-   Registration with normalized email or username.
-   Login with password.
-   Password hashing using Argon2id or bcrypt via a maintained library.
-   Generic login errors that do not disclose whether an account exists.
-   Short-lived access credentials and refresh-token
    rotation/revocation, or a carefully documented secure opaque-session
    design.
-   Logout and logout-all-sessions.
-   Server-side authorization checks.
-   Rate limiting for registration, login, token refresh, and message
    sending.
-   Input validation and maximum request sizes.
-   TLS in deployment; never send passwords or bearer tokens over plain
    public HTTP/WebSocket.
-   Secure storage of client credentials on Android and Windows.
-   Secret configuration through environment variables or protected
    runtime configuration.
-   CORS and origin policy for HTTP/WebSocket where applicable.
-   Safe error responses that do not expose stack traces or database
    details.

Do not implement end-to-end encryption as a home-grown cryptographic
feature. For the first release, use TLS in transit and clearly state
that the server can access stored message content. If E2EE is added
later, use a reviewed protocol/library and document device identity, key
verification, key backup, multi-device sessions, and recovery
limitations.

## 8. Database design

Use migrations and foreign keys. Start with tables for:

-   `users`
-   `sessions` or `refresh_tokens`
-   `devices` (can be minimal in the first milestone)
-   `conversations`
-   `conversation_members`
-   `messages`
-   `message_receipts` (or an equivalent delivery/read state table)

Suggested message fields include:

-   Internal message ID.
-   Conversation ID.
-   Sender user ID.
-   Client message ID/idempotency key.
-   Message type.
-   Text/body or structured payload.
-   Server-created timestamp.
-   Optional edited/deleted timestamps.
-   A conversation-scoped sequence/cursor if needed.

Add unique constraints for idempotency, indexes for conversation history
and membership lookups, and appropriate cascading/restrictive
foreign-key behaviour.

Use transactions for operations that must be atomic, such as creating a
conversation and its initial membership, or inserting a message and its
durable delivery/outbox record.

Do not store online presence as the sole source of truth in PostgreSQL.
Presence is ephemeral and can be held in memory/ETS or Redis, with a
documented strategy for multiple backend nodes.

Document every migration and explain important indexes and constraints.

## 9. Flutter UI and responsive design

The UI must be **responsive**, not merely stretched to fit a screen.

Support:

-   Android phones in portrait and landscape.
-   Android tablets.
-   Resizable Windows desktop windows.
-   Small desktop window sizes.
-   Keyboard and mouse interaction on Windows.
-   Touch interaction on Android.
-   Light and dark themes.
-   Text scaling and accessibility semantics.
-   Loading, empty, offline, reconnecting, error, and success states.

Use adaptive layouts:

-   On narrow screens, show a conversation list and open a conversation
    as a separate route.
-   On wider screens, use a two-pane layout with the conversation list
    on the left and the selected chat on the right.
-   Do not hard-code one global width or assume a single device size.
-   Use `LayoutBuilder` or an equivalent responsive layout strategy and
    define breakpoints centrally.
-   Prevent message text, buttons, and composer controls from
    overflowing.
-   Support Windows keyboard shortcuts where useful, sensible focus
    order, and visible focus states.
-   Avoid tiny touch targets on Android.
-   Keep visual styling consistent through reusable theme tokens and
    widgets.

Minimum screens:

1.  Splash/session restoration.
2.  Register.
3.  Login.
4.  Conversation list.
5.  Direct chat.
6.  Group chat details/basic member list.
7.  Profile/settings.
8.  Connection/offline status.

Chat screen basics:

-   Message bubbles with clear sender/time distinction.
-   Date separators.
-   Sending, sent/accepted, delivered, and read indicators where
    supported.
-   Retry UI for failed sends.
-   Typing indicator.
-   Scroll-to-latest behaviour without forcing the user to the bottom
    when reading history.
-   Message composer with multiline input.
-   Image attachment selection only after basic text messaging is
    reliable.

## 10. Flutter architecture and local persistence

Keep UI, state, networking, and storage separate.

Suggested layers:

``` text
lib/
├── app/
├── core/
│   ├── config/
│   ├── networking/
│   ├── storage/
│   ├── theme/
│   └── responsive/
├── features/
│   ├── auth/
│   ├── conversations/
│   ├── chat/
│   ├── presence/
│   └── profile/
└── shared/
    ├── models/
    └── widgets/
```

Use repositories so widgets do not call HTTP/WebSocket APIs directly.
Keep WebSocket connection lifecycle in a dedicated service. Handle
reconnect with bounded exponential backoff and jitter. Do not create
multiple competing sockets during rebuilds.

Use local SQLite through Drift (or another maintained option) for cached
conversations/messages and an outbox of pending sends. Define how local
optimistic messages reconcile with server acknowledgements. Never treat
local cache as authoritative server state.

Store secrets using platform secure storage, not plain preferences or
the SQLite chat cache.

## 11. Testing requirements

Backend:

-   Unit tests for domain validation and protocol parsing.
-   Tests for password hashing and authentication flows.
-   Repository integration tests against PostgreSQL.
-   SQLite adapter tests if that adapter is implemented.
-   WebSocket tests for authentication, malformed messages, size limits,
    reconnect and authorization.
-   OTP tests for supervisor restart behaviour and worker termination.
-   Tests for duplicate message submission and idempotency.
-   Tests for conversation membership and unauthorized access.

Flutter:

-   Unit tests for models, repositories and state management.
-   Widget tests for login, conversation list and chat screen.
-   Responsive layout tests at narrow, tablet and desktop widths.
-   Tests for reconnect, duplicate acknowledgements and pending-send
    reconciliation.
-   Integration smoke test for register → login → send message → receive
    message.

Provide repeatable commands for all tests. Do not claim tests passed
unless they were actually run.

## 12. Observability and operations

Add:

-   Structured logs with timestamps, severity, request/connection
    correlation IDs.
-   Metrics for active connections, connection failures, message
    throughput, queue/mailbox depth where measurable, database pool
    usage, and reconnects.
-   Health and readiness endpoints.
-   Graceful shutdown.
-   Database backup and restore instructions.
-   Configurable limits for connections, message sizes, and rate limits.
-   A Docker Compose development environment for PostgreSQL if Docker is
    available, but keep native local run instructions too.

Never log credentials, tokens, passwords, private keys, or message
content.

## 13. Documentation is mandatory

Write documentation as you implement. Do not postpone all documentation
until the end.

For every important module and non-obvious function, explain:

-   What it does.
-   Why it exists.
-   Inputs and outputs.
-   Which process owns its state.
-   How it communicates with other modules.
-   What can fail and how failures are handled.
-   Any performance or security trade-offs.

Required documents:

-   `README.md`: project overview and quick start.
-   `docs/architecture.md`: components, supervision tree, data flow, and
    boundaries.
-   `docs/learning-guide.md`: Erlang/OTP concepts explained using this
    actual codebase.
-   `docs/protocol.md`: Protobuf schemas, WebSocket binary message rules, event variants, errors, IDs, versioning, compatibility, and delivery semantics.
-   `docs/database.md`: schema, migrations, transactions, indexes and
    PostgreSQL/SQLite differences.
-   `docs/security.md`: authentication, password hashing, token
    lifecycle, TLS, authorization and known limitations.
-   `docs/operations.md`: configuration, run, test, build, deploy,
    backup, restore and troubleshooting.
-   `docs/decisions/`: short architecture decision records for
    meaningful choices.

Prefer concrete examples and diagrams (Mermaid is welcome). Explain
unfamiliar Erlang syntax rather than assuming the reader already knows
it. Include references to official documentation for dependencies and
OTP concepts.

## 14. Implementation sequence

Work in small, reviewable milestones. At the end of each milestone:

1.  Ensure the code compiles.
2.  Run relevant tests.
3.  Update documentation.
4.  Summarize files changed and architectural decisions.
5.  Explain the Erlang/Flutter concepts introduced.
6.  List known limitations and the next milestone.
7.  Do not silently continue into a much larger milestone without
    reporting the completed stage.

Recommended milestones:

### Milestone 0 --- Repository and toolchain

-   Check installed Erlang/OTP, rebar3, Flutter, Android SDK, and
    Windows desktop toolchain.
-   Create the repository layout.
-   Add configuration examples and documentation skeleton.
-   Record tested tool versions.

### Milestone 1 --- OTP foundation and database

-   Create the Erlang OTP application and supervision tree.
-   Start Cowboy health endpoint.
-   Connect to PostgreSQL.
-   Add migrations and a database health check.
-   Add a documented optional SQLite adapter only if practical.

### Milestone 2 --- Authentication

-   Registration, login, secure password hashing, session/refresh
    handling, logout.
-   Add Flutter register/login screens and secure token storage.

### Milestone 3 --- First real-time chat

-   Authenticated WebSocket connection.
-   Direct conversation creation/listing.
-   Send, persist, and receive text messages.
-   Add client message IDs and server acknowledgements.
-   Implement a basic responsive Flutter chat UI.

### Milestone 4 --- Reliability

-   Reconnect, history sync, pagination, deduplication, offline outbox
    and delivery/read receipts.
-   Test network interruption and duplicate sends.

### Milestone 5 --- Presence and groups

-   Online/last-seen, typing indicators, group conversations and
    membership authorization.

### Milestone 6 --- Desktop/mobile polish

-   Responsive Android and Windows UI, accessibility, keyboard support,
    theme, loading and error states.

### Milestone 7 --- Advanced learning

-   Benchmark connections and message throughput.
-   Investigate OTP supervision patterns and mailbox backpressure.
-   Explore multi-node architecture and distributed Erlang in an
    isolated development environment.
-   Study Protobuf wire encoding, schema evolution, cross-language generated bindings, and binary WebSocket frames without changing domain logic.
-   Add attachments only after the core text-message path is reliable.

## 15. Working rules

-   Inspect the existing repository before changing it. Preserve useful
    work.
-   Ask before destructive operations or replacing existing files.
-   Do not invent dependency APIs. Consult the installed version's
    documentation.
-   Do not use deprecated APIs when a maintained alternative exists.
-   Keep functions and modules small and named by responsibility.
-   Avoid premature microservices. Start with a modular monolith and
    clear internal boundaries.
-   Do not build custom cryptography.
-   Do not expose database ports, Erlang distribution ports, remote
    shells, or admin endpoints publicly by default.
-   Do not commit `.env`, secrets, signing keys, or production data.
-   Keep all examples runnable and all configuration names consistent.
-   If a requirement is ambiguous, state the assumption in the docs and
    ask only when it blocks implementation.

**Definition of done for the first usable release:** a user can register
on Android or Windows, log in, create/open a direct conversation, send
and receive persisted text messages in real time, reconnect after a
network interruption, and use the interface comfortably at narrow mobile
and resizable desktop widths. The owner can run the backend and clients
locally by following the setup guide.
