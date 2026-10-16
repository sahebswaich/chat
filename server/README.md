# Nimbus server

A single **Cloudflare Worker** (TypeScript) with a **D1** (SQLite) database. It holds your
Claude API key, hands out invite codes, enforces per-person daily limits and streams Claude's
answers to the Nimbus app. The Claude key never ships inside the app.

The HTTP API is the contract in [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) ("Server
API"). This file covers deployment, configuration, the owner CLI, and the details the
contract leaves open.

```
src/index.ts     router + error handling        src/chat.ts     POST /v1/chat → Claude → SSE
src/users.ts     redeem, me, delete me, report  src/prompts.ts  system prompts per surface × style
src/auth.ts      bearer tokens, admin token,    src/admin.ts    /admin/* (invites, users, reports)
                 daily-limit counters           src/cards.ts    /v1/cards, /c/:id
src/pages.ts     /join, /privacy, /terms,       src/util.ts     codes, tokens, hashing, time
                 /support, /c/:id HTML           migrations/     D1 schema (applied in order)
scripts/admin.mjs   owner CLI (npm run admin)    test/           vitest inside workerd, Claude mocked
```

## Deploy (Mac, about 10 minutes)

The easy way: run `./scripts/setup-mac.sh` from the repo root. It does everything below
and also configures the Xcode project. To do it by hand:

**You need:** a Mac with [Node.js](https://nodejs.org) 22.12 or newer (`node -v` to check;
`brew install node` if you use Homebrew), a free [Cloudflare account](https://dash.cloudflare.com/sign-up),
and a Claude API key from [platform.claude.com](https://platform.claude.com) → Settings → API keys
(this is separate from a claude.ai subscription; you pay per use).

Open **Terminal** and run these one at a time. Lines starting with `#` are notes; don't paste
them (macOS's zsh doesn't treat `#` as a comment when you type or paste commands).

```bash
# 1. Install the server's tools (into server/node_modules; nothing global).
cd ~/chat/server
npm install

# 2. Sign in to Cloudflare (opens your browser; click Allow).
npx wrangler login

# 3. Write your secrets to a private temporary file (mktemp makes one only you can read).
#    Replace sk-ant-... with your Claude key (and the email) before pressing Return.
#    The admin token is a random password for the owner commands; it is saved in step 5.
ADMIN_TOKEN=$(openssl rand -hex 32)
SECRETS_FILE=$(mktemp)
cat > "$SECRETS_FILE" <<EOF
ANTHROPIC_API_KEY=sk-ant-...
ADMIN_TOKEN=$ADMIN_TOKEN
SUPPORT_EMAIL=you@example.com
EOF

# 4. Deploy. The first deploy also creates the "nimbus" D1 database automatically.
#    Note the https://nimbus.<your-subdomain>.workers.dev URL it prints.
npx wrangler deploy --secrets-file "$SECRETS_FILE"
rm "$SECRETS_FILE"
#    Then create the tables (answer "y"):
npx wrangler d1 migrations apply nimbus --remote

# 5. Save the server URL and admin token for the owner commands (this file is git-ignored).
#    Replace the URL with the one from step 4.
printf '{\n  "url": "%s",\n  "adminToken": "%s"\n}\n' "https://nimbus.<your-subdomain>.workers.dev" "$ADMIN_TOKEN" > .nimbus-admin.json
chmod 600 .nimbus-admin.json

# 6. Check it works (it prints {"ok":true}) and make your first invite.
curl https://nimbus.<your-subdomain>.workers.dev/health
npm run admin -- invite "Your Name"
```

The invite command prints a code like `K7QM-2XPA` and a link
`https://nimbus.<your-subdomain>.workers.dev/join/K7QM-2XPA`. Open the link on your iPhone,
or type the code in the app.

**Updating later:** `git pull`, then `cd server && npm install && npm run deploy` (applies any
new database migrations, answer "y", then deploys the code, so new code never runs against an old
schema). Secrets are kept between deploys.

**Free plan CPU limit.** On the Workers Free plan each request gets 10 ms of CPU time. Waiting
for Claude doesn't count, but reading Claude's stream does: in a local benchmark the SDK used
about 1–8 ms for a short iMessage-style answer (~60 chunks) and 10–45 ms for a long app answer
(1,500–3,000 chunks). Short answers fit; long ones can stop partway, with "exceeded CPU" in
`npx wrangler tail`. If that happens, switch to the Workers Paid plan (Cloudflare dashboard →
Workers & Pages → Plans; 30 s of CPU per request by default). No code change is needed.

**Changing a secret:** `npx wrangler secret put ANTHROPIC_API_KEY` (or `ADMIN_TOKEN`,
`SUPPORT_EMAIL`), paste the value, done. It takes effect within seconds; no redeploy. If you
change `ADMIN_TOKEN`, update `.nimbus-admin.json` too.

> Why the secrets file on the first deploy? `wrangler.jsonc` lists `ANTHROPIC_API_KEY` and
> `ADMIN_TOKEN` as required secrets, and a Worker that doesn't exist yet can't have secrets set in
> advance, so wrangler asks for them with the first deploy. After that, `wrangler secret put` works.

## Point the app at your server

The app needs only the **host** (no `https://`, no path):

* **Build setting:** in `Config/Local.xcconfig` (copy `Config/Local.xcconfig.example`) set
  `NIMBUS_API_HOST = nimbus.<your-subdomain>.workers.dev`. It ends up in the app's Info.plist as
  `NimbusAPIHost`. (Host only, because `//` starts a comment in xcconfig files.)
* **Invite links set it too:** the "Open Nimbus" button on `/join/<code>` opens
  `nimbus://join?code=K7QM-2XPA&host=nimbus.<your-subdomain>.workers.dev`, which signs the
  person in to that server.
* The app's Settings can also override the server host.

For App Store Connect / TestFlight, use `https://nimbus.<your-subdomain>.workers.dev/privacy` as
the privacy policy URL, `/terms` for terms and `/support` as the support URL. Make an invite for
Beta App Review with `npm run admin -- invite "App Review" --uses 5` and paste the code in the
review notes.

## Settings

Plain settings live in `wrangler.jsonc` → `vars` (edit, then `npm run deploy`):

| var | default | meaning |
|---|---|---|
| `DAILY_LIMIT` | `"200"` | answers per person per UTC day. An invite can set its own (`--limit`). |
| `TESTFLIGHT_URL` | `""` | public TestFlight link; when set (https only), `/join` shows **Install Nimbus from TestFlight**. |
| `MODEL` | `"claude-opus-5-5"` | Claude model for every answer. |

Secrets (`npx wrangler secret put <NAME>`):

| secret | |
|---|---|
| `ANTHROPIC_API_KEY` | required. Your Claude API key. |
| `ADMIN_TOKEN` | required. Protects `/admin/*`; compared in constant time. An empty value disables the admin API. |
| `SUPPORT_EMAIL` | optional. Contact shown in the app (`GET /v1/me` → `supportEmail`, `""` if unset) and on `/support`, `/terms`, `/privacy`. |

`SUPPORT_EMAIL` is read like a var but deliberately **not** declared in `vars`: a var with the
same name would overwrite the secret on every deploy. (The contract calls it a var; the Worker
reads it either way.)

## Owner CLI

```bash
# 1 use, default daily limit
npm run admin -- invite "James"
npm run admin -- invite "Family" --uses 5 --limit 50
# code, name, uses left, daily limit
npm run admin -- invites
# unused codes stop working; people who joined keep access
npm run admin -- revoke-invite K7QM-2XPA
# id, name, device, today's usage, last seen, status
npm run admin -- users
# their token stops working immediately
npm run admin -- revoke-user u_7k2m9qxz4t
# reported answers, newest first
npm run admin -- reports
# any command: raw JSON
npm run admin -- users --json
```

(Copy only the command lines: in macOS's zsh, a pasted `# note` is not a comment.)

It reads `NIMBUS_URL` and `NIMBUS_ADMIN_TOKEN` from the environment, or `server/.nimbus-admin.json`
(`{"url": "...", "adminToken": "..."}`). Node 20+, no dependencies.

## Local development and tests

```bash
# then put a real or dummy key in .dev.vars
cp .dev.vars.example .dev.vars
# applies migrations to a local D1, serves http://localhost:8787
npm run dev
# vitest inside workerd with a local D1; the Claude API is mocked
npm test
# tsc --noEmit (strict)
npm run typecheck
# typecheck + tests + wrangler deploy --dry-run
npm run check
```

The tests never call Claude: `ANTHROPIC_BASE_URL` points the SDK at a fake host and
`test/helpers.ts` answers with Messages-API SSE streams (`message_start`, `content_block_*`,
`message_delta`, `message_stop`, `error` events). Run `npm run types` after changing
`wrangler.jsonc` to regenerate `worker-configuration.d.ts`.

## How it calls Claude

`client.beta.messages.stream(...)` (official `@anthropic-ai/sdk`), then `finalMessage()`:

* `model`: the `MODEL` var (`claude-opus-5-5`). No `thinking` field: thinking is always on
  (adaptive) for this model; `disabled` or `budget_tokens` would be a 400. No `temperature`/`top_p`,
  no assistant prefill.
* `output_config: {effort: "low"}` and `max_tokens: 16000` for the `messages` and `intent`
  surfaces (snappy); `effort: "medium"` and `max_tokens: 64000` for `app`.
* Server-side refusal fallback: `betas: ["server-side-fallback-2026-07-01"]` + `fallbacks: "default"`.
  A policy decline is retried on Anthropic's recommended fallback model inside the same stream. A
  final `stop_reason: "refusal"` (checked on `stop_reason`, never `stop_details`, which may be
  `null`) becomes an `error` event with code `refusal`.
* `webSearch: true` adds `{type: "web_search_20260209", name: "web_search", max_uses: 3}`.
  `stop_reason: "pause_turn"` is resumed by re-sending the conversation with the paused assistant
  content appended (no extra user message), at most 3 times. After a mid-output fallback, the
  blocks before the last `fallback` marker are trimmed to what the API accepts on echo.
* Prompt caching: top-level `cache_control: {type: "ephemeral"}`. The system prompt is one frozen
  string per (surface, style); nothing per-request goes in it. Today's date goes at the start of
  the first user turn instead, and pasted `context` goes in that turn inside a
  `<conversation>…</conversation>` block, labelled as pasted chat text to read as data, not
  instructions (a `</conversation>` inside the pasted text is neutralised).
* All SDK params used (`betas`, `fallbacks`, `output_config`, `cache_control`, the web search tool)
  are in the SDK's TypeScript types, so nothing is passed untyped.
* Errors use the SDK's typed classes: `RateLimitError` and 529 / `overloaded_error` → `overloaded`;
  `AuthenticationError`, `PermissionDeniedError`, connection errors and other API errors →
  `upstream` (logged for you, with a hint to check `ANTHROPIC_API_KEY` on 401/403). The SDK
  retries 429/5xx/529 twice before giving up.

## Decisions where the contract is open

* **Errors after the stream opens.** `/v1/chat` validates, authenticates and checks the daily
  limit first; those failures are normal JSON errors (`401`, `400`, `429`). Once those pass, the
  response is `200 text/event-stream` and `meta` is sent straight away, so **every Claude failure,
  including a 529 before the first token, arrives as an `error` event** (`overloaded`,
  `upstream`, ...), never as an HTTP error status.
* **Event order.** `meta`, then `status` events only when the state changes (`searching` when a
  web search starts, `writing` when text starts; it can go back to `searching` and then `writing`
  again), `delta`s, then exactly one `done` or `error`, then the stream closes. A comment line
  `: ping` is sent whenever 10 s pass without output (the longest silence is about 12.5 s), so
  the app's URLSession, mobile networks and proxies keep the connection open while Claude thinks
  or searches; SSE clients ignore lines starting with `:`. The response has
  `Cache-Control: no-cache, no-transform` so Cloudflare doesn't compress, and so buffer, the stream.
* **Partial answers.** On `refusal` or `max_tokens` some `delta`s may already have been sent;
  the `error` event says the answer is incomplete or declined. `done.stopReason` is normally
  `end_turn`; it is `pause_turn` if a web search was still paused after 3 resumptions but some
  text was produced (with no text, that's an `error` with code `upstream`).
* **`meta.model`** is the configured `MODEL`, sent before Claude is called (a refusal fallback may
  actually serve the answer).
* **Daily limit.** Counted per UTC day, atomically, before Claude is called (concurrent requests
  can't exceed it). The `429 daily_limit` error also carries `resetAt` (ISO time of the next
  UTC midnight) and a `Retry-After` header. A request is **given back** if Claude failed before
  producing any text (`upstream`/`overloaded`, or a search that never finished), so outages
  don't eat people's allowance. Refusals, `max_tokens` and requests the app cancelled still count.
  `done.usedToday` is the count including this request.
* **App disconnects.** When the app closes the connection, the upstream Claude request is aborted
  (`request.signal` via the `enable_request_signal` compatibility flag, plus the response
  stream's `cancel`), so no tokens are spent on an answer nobody reads.
* **Validation.** `messages`: 1–40 entries, roles exactly alternating `user`/`assistant` starting
  and ending with `user`, `content` a non-blank string of at most 20,000 characters (JavaScript
  length, i.e. UTF-16 code units). `context` ≤ 20,000. `style` defaults to `default`, `surface` to
  `messages`, `webSearch` to `false`; `null` counts as absent; unknown extra keys are ignored.
  Bodies over 6 MB are rejected with `400 invalid_request`; the bytes are counted as they
  arrive, so a missing or wrong `Content-Length` doesn't matter. (The largest valid chat body
  is ~2.5 MB of JSON in a non-Latin script, ~4.9 MB if every character is `\uXXXX`-escaped.)
* **Invite codes** are 8 random Crockford base32 characters (no I, L, O, U), stored without the
  dash and shown as `XXXX-XXXX`. Typed codes are uppercased, spaces/dashes removed, and the
  look-alikes `O → 0`, `I`/`L → 1` mapped. Malformed codes get `404 invalid_code`. Uses are taken
  with an atomic `UPDATE … WHERE uses_left > 0`. Guessing is throttled: each client address
  (`CF-Connecting-IP`; IPv6 counted per /64) may try 10 wrong codes per UTC hour (codes that work
  don't count), then gets `429 too_many_attempts` with `Retry-After`. Attempts are counted in the
  `redeem_attempts` table (migration `0004`, keyed by a SHA-256 hash of the hour and address,
  earlier hours deleted as new ones start) before the code is looked up, so parallel guesses can't
  race past the limit; if the table is missing the throttle is skipped rather than blocking sign-ins.
* **Tokens** are 32 random bytes, base64url (43 characters). Only their SHA-256 hash is stored;
  lookup is by hash. Revoked users get `401 unauthorized`. `last_seen_at` is updated on every
  authenticated request.
* **`POST /v1/redeem`**: `device` is optional (≤ 200 characters).
* **`DELETE /v1/me`** removes the user row, usage counters and cards in one transaction; reports
  stay with `user_id` set to `NULL` (shown as `userId: null` in `/admin/reports`).
* **`POST /v1/report`**: `messages` (≤ 40 `{role, content}` items, content ≤ 20,000), `answer`
  (≤ 20,000) and `reason` (≤ 1,000, default `"unspecified"`) are all optional, but a report needs
  messages or an answer.
* **Admin.** `POST /admin/invites`: `uses` 1–10,000 (default 1), `dailyLimit` 0–1,000,000 (default:
  the `DAILY_LIMIT` var, which also applies later if you change it). The invite `url` is
  `https://<host of the request>/join/<code>`. `DELETE /admin/invites/:code` accepts any spelling
  of the code and returns `404 invalid_code` if there's no such invite; people who already joined
  keep access. `POST /admin/users/:id/revoke` returns `404 not_found` for an unknown id.
  `GET /admin/reports` items are `{id, userId, userName, messages, answer, reason, createdAt}`.
  Lists return at most 500 rows, newest first.
* **Other errors:** unknown path `404 not_found`, wrong method `405 method_not_allowed`,
  unexpected failure `500 internal`, all in the contract's error shape.
* **Pages** (`/join/:code`, `/privacy`, `/terms`, `/support`, `/c/:id`) escape every dynamic value
  and send a strict Content-Security-Policy with no scripts.
* **D1 provisioning.** `database_id` is omitted in `wrangler.jsonc`: wrangler 4 creates the
  `nimbus` database on the first `wrangler deploy` and finds it by name afterwards. If you'd rather
  create it yourself, run `npx wrangler d1 create nimbus` and paste the printed `database_id` into
  the `d1_databases` entry.

## Versions

`@anthropic-ai/sdk` 0.135.0, `wrangler` 4.151.0, `vitest` 5.0.5, `@cloudflare/vitest-plugin` 1.4.3
(the renamed successor of `@cloudflare/vitest-pool-workers`, which is deprecated and only supports
vitest 4), `@cloudflare/workers-types` 5.20261015.1, `typescript` 7.0.2. Exact versions are pinned
in `package.json`; `package-lock.json` locks the rest. `compatibility_date` is `2026-10-01`.
