-- Conversations and membership. Delivery/read state is a per-member high-water mark of message
-- sequence numbers (see docs/decisions/0006): cheap to update and exact for "delivered up to N".
CREATE TABLE conversations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind            text NOT NULL CHECK (kind IN ('direct', 'group')),
  title           text,
  direct_key      text UNIQUE,              -- "<lower uuid>:<higher uuid>" so a pair has ONE direct chat
  last_seq        bigint NOT NULL DEFAULT 0,
  last_message_at timestamptz,
  created_by      uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT conversations_direct_key_ck CHECK (
    (kind = 'direct' AND direct_key IS NOT NULL) OR (kind = 'group' AND direct_key IS NULL))
);

CREATE TABLE conversation_members (
  conversation_id    uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role               text NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  joined_at          timestamptz NOT NULL DEFAULT now(),
  last_delivered_seq bigint NOT NULL DEFAULT 0,
  last_read_seq      bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (conversation_id, user_id)
);
CREATE INDEX conversation_members_user_idx ON conversation_members (user_id);
