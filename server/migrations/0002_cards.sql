-- Answers a user chose to send as a Nimbus card bubble. Stored so the card's
-- link (/c/:id) can show the question and answer to people reading the chat
-- where iMessage apps can't run (Mac, Apple Watch). Only created when the user
-- taps "Card"; nothing else from a chat is stored.
CREATE TABLE cards (
  id         TEXT PRIMARY KEY,           -- random 96-bit base64url id (16 chars)
  user_id    TEXT NOT NULL,
  question   TEXT NOT NULL,
  answer     TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX cards_user_id ON cards (user_id);
