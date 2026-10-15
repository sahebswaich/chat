-- DELETE /v1/me removes a user's account but keeps their reports for moderation,
-- with the link to the user removed. SQLite can't drop NOT NULL in place, so the
-- reports table is rebuilt with a nullable user_id (NULL = account deleted).

CREATE TABLE reports_new (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    TEXT,                       -- NULL once the reporter deleted their account
  messages   TEXT NOT NULL,              -- JSON array of {role, content}
  answer     TEXT NOT NULL,
  reason     TEXT NOT NULL,
  created_at TEXT NOT NULL
);

INSERT INTO reports_new (id, user_id, messages, answer, reason, created_at)
  SELECT id, user_id, messages, answer, reason, created_at FROM reports;

DROP TABLE reports;
ALTER TABLE reports_new RENAME TO reports;

CREATE INDEX reports_created_at ON reports (created_at);
CREATE INDEX reports_user_id ON reports (user_id);
