CREATE TABLE messages (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id   uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  seq               bigint NOT NULL,
  sender_id         uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  client_message_id text NOT NULL,
  kind              text NOT NULL DEFAULT 'text',
  body              text NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  edited_at         timestamptz,
  deleted_at        timestamptz,
  -- history/sync pages read by (conversation_id, seq range): this unique index serves them
  CONSTRAINT messages_conv_seq_unique UNIQUE (conversation_id, seq),
  -- idempotent sends: a retried client_message_id can never create a second row
  CONSTRAINT messages_idempotency_unique UNIQUE (sender_id, client_message_id)
);
