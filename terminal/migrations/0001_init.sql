-- Trading terminal schema.

-- Share links: URLs (/s/<token>) that open the terminal read-only without the password.
-- Only the token's SHA-256 is stored.
CREATE TABLE shares (
  id          TEXT PRIMARY KEY,
  token_hash  TEXT NOT NULL UNIQUE,
  label       TEXT NOT NULL,
  scope       TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('view', 'comment')),
  created_at  TEXT NOT NULL,
  expires_at  TEXT,
  revoked_at  TEXT,
  last_used_at TEXT
);

-- Failed sign-in attempts per client, to slow down password guessing.
CREATE TABLE login_attempts (
  client      TEXT NOT NULL,
  at          TEXT NOT NULL
);
CREATE INDEX login_attempts_client ON login_attempts (client, at);

-- Hourly market snapshots written by the cron trigger (one row per coin per hour).
CREATE TABLE market_snapshots (
  ts          TEXT NOT NULL,
  coin        TEXT NOT NULL,
  mark        REAL,
  funding_hourly REAL,
  oi_usd      REAL,
  agg_oi_usd  REAL,
  market_cap  REAL,
  korea_share REAL,
  korea_turnover_krw REAL,
  PRIMARY KEY (coin, ts)
);
CREATE INDEX market_snapshots_ts ON market_snapshots (ts);

-- Trade journal: fills typed in or pasted as CSV.
CREATE TABLE fills (
  id          TEXT PRIMARY KEY,
  account     TEXT NOT NULL DEFAULT 'main',
  coin        TEXT NOT NULL,
  side        TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
  price       REAL NOT NULL,
  size        REAL NOT NULL,
  leverage    REAL,
  filled_at   TEXT NOT NULL,
  note        TEXT NOT NULL DEFAULT '',
  created_at  TEXT NOT NULL
);
CREATE INDEX fills_coin ON fills (coin, filled_at);
