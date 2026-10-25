-- Operating Room schema.

-- Share links: Excalidraw-style URLs (/s/<token>) that open part of the room without the
-- owner password. Only the token's SHA-256 is stored.
CREATE TABLE shares (
  id          TEXT PRIMARY KEY,
  token_hash  TEXT NOT NULL UNIQUE,
  label       TEXT NOT NULL,
  -- Path prefix the link opens, e.g. "/terminal", "/treatise" or "/p/my-memo".
  scope       TEXT NOT NULL,
  -- "view" can read; "comment" can also post in the discussion.
  role        TEXT NOT NULL CHECK (role IN ('view', 'comment')),
  created_at  TEXT NOT NULL,
  expires_at  TEXT,
  revoked_at  TEXT,
  last_used_at TEXT
);

-- Published pages: /p/<slug> (and <slug>.<PUBLISH_HOST_SUFFIX> when configured).
CREATE TABLE publications (
  slug        TEXT PRIMARY KEY,
  title       TEXT NOT NULL,
  -- "markdown" is rendered into the paper template; "html" is served as written, sandboxed.
  kind        TEXT NOT NULL CHECK (kind IN ('markdown', 'html')),
  body        TEXT NOT NULL,
  -- "private": owner and share links only. "public": anyone with the URL.
  visibility  TEXT NOT NULL CHECK (visibility IN ('private', 'public')),
  -- Optional full hostname that serves this page (e.g. "memo.example.com").
  custom_host TEXT UNIQUE,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

-- Discussion threads, attached to a page path and optionally a section anchor.
CREATE TABLE comments (
  id          TEXT PRIMARY KEY,
  page        TEXT NOT NULL,
  anchor      TEXT NOT NULL DEFAULT '',
  parent_id   TEXT,
  author      TEXT NOT NULL,
  body        TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  resolved_at TEXT
);
CREATE INDEX comments_page ON comments (page, created_at);

-- Failed sign-in attempts per client, to slow down password guessing.
CREATE TABLE login_attempts (
  client      TEXT NOT NULL,
  at          TEXT NOT NULL
);
CREATE INDEX login_attempts_client ON login_attempts (client, at);
