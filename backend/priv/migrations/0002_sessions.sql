-- Devices are informational; sessions carry the tokens. Only SHA-256 hashes of tokens are stored.
CREATE TABLE devices (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform     text NOT NULL,
  label        text,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX devices_user_idx ON devices (user_id);

CREATE TABLE sessions (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id             uuid REFERENCES devices(id) ON DELETE SET NULL,
  access_hash           bytea NOT NULL,
  access_expires_at     timestamptz NOT NULL,
  refresh_hash          bytea NOT NULL,
  previous_refresh_hash bytea,            -- the token this one replaced; presenting it again = reuse
  refresh_expires_at    timestamptz NOT NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),
  last_used_at          timestamptz NOT NULL DEFAULT now(),
  revoked_at            timestamptz
);
CREATE UNIQUE INDEX sessions_access_hash_idx ON sessions (access_hash);
CREATE UNIQUE INDEX sessions_refresh_hash_idx ON sessions (refresh_hash);
CREATE INDEX sessions_previous_refresh_idx ON sessions (previous_refresh_hash) WHERE previous_refresh_hash IS NOT NULL;
CREATE INDEX sessions_user_active_idx ON sessions (user_id) WHERE revoked_at IS NULL;
