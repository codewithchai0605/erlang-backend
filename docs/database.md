# Database (PostgreSQL)

Migrations: `backend/priv/migrations/NNNN_name.sql`, forward-only, applied in order at startup by `chat_migrate` (each in its own transaction, recorded in `schema_migrations`, guarded by an advisory lock). Disable with `CHAT_RUN_MIGRATIONS=false` and run `chat_migrate:run()` yourself. Requires PostgreSQL 13+ (`gen_random_uuid()` is built in).

| Table | Purpose | Notable constraints / indexes |
|---|---|---|
| users | accounts | `username` unique, lowercase CHECK, length CHECKs |
| devices | informational: platform/label per sign-in | index on user_id |
| sessions | token hashes (access + refresh + previous refresh), expiry, revocation | unique indexes on access_hash and refresh_hash; partial index on previous_refresh_hash; partial index on active sessions per user |
| conversations | direct/group, `last_seq`, `last_message_at` | `direct_key` unique ("lowId:highId") gives exactly one direct chat per pair; CHECK ties kind to direct_key |
| conversation_members | membership + `last_delivered_seq` / `last_read_seq` | PK (conversation_id, user_id); index on user_id |
| messages | message rows | UNIQUE (conversation_id, seq) serves history/sync; UNIQUE (sender_id, client_message_id) enforces idempotent sends |

Design notes:

- **Receipts as high-water marks** (ADR 0006) instead of a row per message and recipient: "delivered up to N" is one integer per member, updated with `GREATEST` (monotonic) and clamped to `last_seq`.
- **Gap-free sequence numbers** come from `UPDATE conversations SET last_seq = last_seq + 1 ... RETURNING` inside the insert transaction; the row lock serialises concurrent senders in the same conversation (and does not affect other conversations).
- **Timestamps** leave PostgreSQL as epoch milliseconds so the Erlang side needs no date decoding.
- Presence is ephemeral and is never stored here.
- Message text is stored in plain text (no end-to-end encryption in v1; see security.md). Message content is never logged.
