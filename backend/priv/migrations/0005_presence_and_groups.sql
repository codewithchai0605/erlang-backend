-- Milestone 5: last-seen persistence and group-conversation semantics.
--
-- users.last_seen_at: written when a user's LAST connection closes (after a short grace period). "Online" is
-- never stored: it is derived from live connections in memory (chat_presence), so a crash cannot leave
-- stale "online" rows behind. NULL = never connected since this column existed.
ALTER TABLE users ADD COLUMN last_seen_at timestamptz;

-- conversation_members.history_from_seq: the conversation's last_seq at the moment the member joined.
-- History and sync only return messages with seq > history_from_seq, so a newly added group member cannot
-- read what was said before they joined. Direct-chat members keep the default 0 (full history).
ALTER TABLE conversation_members ADD COLUMN history_from_seq bigint NOT NULL DEFAULT 0;

-- Group conversations must be named; every title is bounded. Direct conversations stay untitled.
ALTER TABLE conversations ADD CONSTRAINT conversations_title_len
  CHECK (title IS NULL OR char_length(title) BETWEEN 1 AND 100);
ALTER TABLE conversations ADD CONSTRAINT conversations_group_has_title
  CHECK (kind = 'direct' OR title IS NOT NULL);
