-- Users. Username is stored lowercase (enforced by CHECK); display_name keeps the user's casing.
CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username      text NOT NULL,
  display_name  text NOT NULL,
  password_hash text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT users_username_unique UNIQUE (username),
  CONSTRAINT users_username_lower CHECK (username = lower(username)),
  CONSTRAINT users_username_len CHECK (char_length(username) BETWEEN 3 AND 32),
  CONSTRAINT users_display_name_len CHECK (char_length(display_name) BETWEEN 1 AND 50)
);
