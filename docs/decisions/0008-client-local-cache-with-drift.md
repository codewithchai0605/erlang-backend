# 0008 - Drift database as cache and outbox; clientMessageId as primary key
Status: accepted
Decision: the UI reads only from the local database. Unsent messages are rows with status `pending`/`failed` (the outbox). Every message is keyed by `clientMessageId`, which the server echoes, so accepting a send, receiving a duplicate push and syncing are all the same idempotent upsert.
Consequences: instant, offline-capable UI and crash-safe sending. Requires `build_runner` for Drift's generated code. The cache is wiped on sign-out. Windows/Android SQLite binaries come from drift_flutter (verify on first build).
