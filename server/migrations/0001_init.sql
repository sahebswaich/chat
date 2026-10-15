-- Nimbus initial schema.
-- Timestamps are ISO-8601 UTC strings; days are 'YYYY-MM-DD' (UTC).

-- Invite codes the owner hands out. `code` is stored normalised:
-- 8 Crockford base32 characters, uppercase, no dash (shown as XXXX-XXXX).
CREATE TABLE invites (
  code        TEXT PRIMARY KEY,
  name        TEXT NOT NULL,             -- who the invite is for, e.g. "James"
  uses_left   INTEGER NOT NULL CHECK (uses_left >= 0),
  daily_limit INTEGER,                   -- NULL = use the DAILY_LIMIT var
  created_at  TEXT NOT NULL
);

-- One row per redeemed device. The bearer token itself is never stored,
-- only its SHA-256 hash (lowercase hex).
CREATE TABLE users (
  id           TEXT PRIMARY KEY,
  token_hash   TEXT NOT NULL UNIQUE,
  name         TEXT NOT NULL,
  device       TEXT,
  invite_code  TEXT,
  daily_limit  INTEGER,                  -- NULL = use the DAILY_LIMIT var
  created_at   TEXT NOT NULL,
  last_seen_at TEXT,
  revoked_at   TEXT
);

-- Requests per user per UTC day. Incremented with an atomic upsert.
CREATE TABLE usage (
  user_id TEXT NOT NULL,
  day     TEXT NOT NULL,
  count   INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, day)
);

-- Answers a user explicitly flagged with "Report". The only chat content
-- the server ever stores.
CREATE TABLE reports (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    TEXT NOT NULL,
  messages   TEXT NOT NULL,              -- JSON array of {role, content}
  answer     TEXT NOT NULL,
  reason     TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX reports_created_at ON reports (created_at);
CREATE INDEX invites_created_at ON invites (created_at);
CREATE INDEX users_created_at ON users (created_at);
