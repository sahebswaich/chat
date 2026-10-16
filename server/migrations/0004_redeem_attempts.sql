-- Invite-code redemptions per client per UTC hour, to slow down guessing invite codes
-- (POST /v1/redeem answers 429 too_many_attempts past the limit). `client` is a SHA-256
-- hash of the hour and the caller's address (an IPv6 address reduced to its /64), never
-- the address itself. Rows from earlier hours are deleted by later redemptions.
CREATE TABLE redeem_attempts (
  client TEXT NOT NULL,
  hour   TEXT NOT NULL,                  -- 'YYYY-MM-DDTHH' (UTC)
  count  INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (client, hour)
);

CREATE INDEX redeem_attempts_hour ON redeem_attempts (hour);
