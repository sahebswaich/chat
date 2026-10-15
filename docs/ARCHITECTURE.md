# Nimbus — architecture & contracts

Nimbus is an iPhone/iPad App Store app with an AI that also lives in the iMessage **+** apps
drawer. You ask it something, it streams an answer, and you send that
answer into the conversation as a normal text bubble or as a Nimbus card bubble.
Friends get access through **invite codes**; all AI calls go through a small
server that holds the Claude API key, so the key never ships inside the app.

```
 iPhone / iPad                                          Cloudflare Worker (server/)
 ┌───────────────────────────────┐   HTTPS + SSE    ┌──────────────────────────────┐
 │ Nimbus.app (SwiftUI app)      │ ───────────────▶ │ /v1/redeem  invite → token   │
 │  • chat, history, settings    │                  │ /v1/chat    stream answer    │──▶ Claude API
 │  • App Intents (Siri, Action  │ ◀─────────────── │ /v1/me      usage            │    (claude-opus-5-5)
 │    Button, Spotlight)         │   event-stream   │ /v1/report  flag an answer   │
 │ NimbusMessages.appex (iMessage│                  │ /admin/*    invites (owner)  │
 │  + drawer extension)          │                  │ /join/:code landing page     │
 │ NimbusWidgets.appex (Live     │                  │ /privacy    privacy policy   │
 │  Activity, Control Center)    │                  │ D1 (SQLite): invites, users, │
 └───────────────────────────────┘                  │ usage, reports, cards        │
                                                     │ /v1/cards + /c/:id  card web │
                                                     │ pages (web fallback)         │
                                                     └──────────────────────────────┘
```

## Names & identifiers

| Thing | Value |
|---|---|
| Product name | **Nimbus** (display name in the + drawer) |
| Base bundle id | `$(NIMBUS_BUNDLE_ID)` – default `com.sahebswaich.nimbus` (set in `Config/Base.xcconfig`, override in `Config/Local.xcconfig`) |
| Messages extension | `$(NIMBUS_BUNDLE_ID).messages` |
| Widgets extension (iOS only) | `$(NIMBUS_BUNDLE_ID).widgets` |
| Shared keychain group | `$(AppIdentifierPrefix)$(NIMBUS_BUNDLE_ID).shared` (Info.plist key `NimbusKeychainGroup`) |
| Server host | `$(NIMBUS_API_HOST)` → Info.plist key `NimbusAPIHost` (host only, no scheme — `//` starts a comment in xcconfig) |
| URL scheme | `nimbus://` (`nimbus://join?code=XXXX-XXXX&host=…`, `nimbus://ask?q=…`) |
| Min OS | iOS / iPadOS 26.0 |
| Language | Swift 6 language mode, default actor isolation = MainActor, SwiftUI, Observation, SwiftData, Swift Testing |

## Repository layout

```
Nimbus.xcodeproj           native Xcode project (synchronized folders – add files in Xcode normally)
Config/                    xcconfigs, Info.plists, entitlements (not a synchronized folder)
Shared/                    code compiled into the app, both extensions and the tests
App/                       iOS/iPadOS app
MessagesExtension/         iMessage app extension
Widgets/                   Live Activity + Control Center control (iOS only)
Tests/                     Swift Testing unit tests (hostless, run on the iOS simulator)
server/                    Cloudflare Worker (TypeScript) + D1 migrations + tests
scripts/                   one-command setup on your Mac, TestFlight upload
.github/workflows/         CI build, TestFlight upload, server test/deploy
docs/                      this file, setup guide, privacy policy text
```

## Server API (contract shared by Swift and TypeScript)

All JSON. Errors are always `{"error": {"code": "<snake_case>", "message": "<human text>"}}`
with a suitable HTTP status. Authenticated routes take `Authorization: Bearer <token>`.

### `POST /v1/redeem`
Request `{"code": "K7QM-2XPA", "device": "Saheb's iPhone"}` (code is case-insensitive;
dashes/spaces ignored). Response `200 {"token": "<opaque>", "name": "James", "dailyLimit": 200}`.
Errors: `400 invalid_request`, `404 invalid_code`, `410 code_used_up`.

### `GET /v1/me`
Response `200 {"name": "James", "usedToday": 12, "dailyLimit": 200}`. `401 unauthorized`.

### `POST /v1/chat` → `text/event-stream`
Request:
```json
{
  "messages": [{"role": "user", "content": "what is nephilim"}],
  "style": "default",          // default | short | funny | formal | explain | reply | factcheck
  "surface": "messages",       // messages | app | intent
  "context": "optional pasted conversation text",
  "webSearch": true
}
```
`messages` alternate user/assistant, start and end with `user`, max 40 entries, each ≤ 20k chars;
`context` ≤ 20k chars. Response is SSE; every event has an `event:` line and one `data:` JSON line:

| event | data | meaning |
|---|---|---|
| `meta` | `{"model": "claude-opus-5-5"}` | stream opened |
| `status` | `{"state": "searching"}` / `{"state": "writing"}` | progress (web search started / text started) |
| `delta` | `{"text": "…"}` | answer text chunk, append in order |
| `done` | `{"stopReason": "end_turn", "usedToday": 13, "dailyLimit": 200}` | finished |
| `error` | `{"code": "refusal", "message": "…"}` | failed mid-stream; codes: `refusal`, `upstream`, `overloaded`, `max_tokens` |

Pre-stream errors are normal JSON errors: `401 unauthorized`, `400 invalid_request`,
`429 daily_limit` (`message` says when it resets).

### `POST /v1/cards`
Request `{"question": "what is nephilim", "answer": "…"}` (≤ 2k / 20k chars) →
`200 {"id": "<12+ char id>", "url": "https://<host>/c/<id>"}`. The iMessage card bubble uses
this URL as `MSMessage.url`: people reading the chat on a Mac or Apple Watch can't run iMessage
apps, and clicking a card there opens the URL in the browser, so `/c/:id` shows the question and answer as a nice page.

### `GET /c/:id` and `GET /c/:id.json`
Public HTML page showing the card (question, answer, "Answered by Nimbus"); 404 page if
unknown. `/c/:id.json` returns `{"id", "question", "answer", "createdAt"}` for the extension
when the copy carried in the message URL was truncated. Ids are random (≥ 72 bits) and unguessable.

**Card URL format** (what goes in `MSMessage.url`):
`https://<host>/c/<id>?q=<question ≤ 280 chars>&a=<answer, truncated>&v=1` (URL-encoded query
items). `MSMessage.url` is capped at 5,000 characters, so trim `a` until the whole URL is ≤ 4,000
characters (emoji and non-Latin text triple in size when percent-encoded); a trailing `…` marks a
truncated answer. The extension shows the card from `q`/`a` without a network call and fetches
`/c/:id.json` only when the answer was truncated. The server ignores the query string.

### `POST /v1/report`
Request `{"messages": [...], "answer": "…", "reason": "offensive"}` → `204`. Stored for the owner.

### Owner/admin (header `Authorization: Bearer $ADMIN_TOKEN`)
* `POST /admin/invites` `{"name": "James", "uses": 1, "dailyLimit": 200}` → `{"code": "K7QM-2XPA", "url": "https://<host>/join/K7QM-2XPA"}`
* `GET /admin/invites` → `{"invites": [{code, name, usesLeft, dailyLimit, createdAt}]}`
* `DELETE /admin/invites/:code` → `204`
* `GET /admin/users` → `{"users": [{id, name, device, createdAt, lastSeenAt, usedToday, revoked}]}`
* `POST /admin/users/:id/revoke` → `204`
* `GET /admin/reports` → `{"reports": [...]}`

### Public pages
* `GET /health` → `{"ok": true}`
* `GET /join/:code` → HTML landing page: “Install Nimbus from TestFlight” (uses `TESTFLIGHT_URL` var if set) + “Open Nimbus” button to `nimbus://join?code=…&host=…`, and the code in big type to type manually.
* `GET /privacy` → HTML privacy policy (needed for external TestFlight testing).

## AI behaviour

* Model `claude-opus-5-5` through `client.beta.messages.stream` with server-side refusal
  fallback (`betas: ["server-side-fallback-2026-07-01"]`, `fallbacks: "default"`).
  Thinking is adaptive (always on for this model); effort `low` for `messages`/`intent`
  surfaces (snappy), `medium` for `app`.
* Web search tool `web_search_20260209` (max 3 uses) when `webSearch` is true; `pause_turn`
  is resumed server-side (max 3 continuations).
* Messages/intent surfaces: answers are plain text (iMessage does not render Markdown), short
  and conversational, sound like a text message. App surface: Markdown allowed.
* Styles change the system prompt: `reply` = write the reply *as the user* to the pasted
  conversation; `factcheck` = check the claim; `explain` = explain simply; etc.

## Swift modules (folders)

* **Shared/** – `NimbusClient` (async SSE client: `stream(_ request:) -> AsyncThrowingStream<ChatEvent, Error>`),
  `SSEParser`, request/response models, `ChatStyle`, `NimbusConfig` (host from Info.plist or
  user override), `TokenStore` (shared keychain), `Haptics`, design system (`NimbusTheme`,
  glass card, typing-dots indicator, bubble shape), `CardPayload` (encode/decode the card URL format
  above), `NimbusActivityAttributes` (Live Activity, iOS only), `OpenAskIntent`.
* **App/** – SwiftUI app: onboarding (invite code / deep link), chat with streaming answers
  stored in SwiftData, “Add to iMessage” guide, settings (server, usage, sign out), App Intents
  (`AskNimbusIntent` + `AppShortcutsProvider`), Live Activity while an answer streams.
* **MessagesExtension/** – `MessagesViewController` (MSMessagesAppViewController hosting
  SwiftUI). Compact: quick actions (paste conversation → reply / explain / fact-check / roast),
  recent answers, tap the prompt bar to expand. Expanded: composer, streaming answer with
  iMessage-style typing dots, actions: **Send** (text bubble), **Card** (an `MSMessage` with an
  `MSMessageTemplateLayout`: a rendered card image + caption. Live layouts are avoided because of an
  open iOS 26/27 bug where they get stuck on "Loading…"), **Insert** (drop into the text field to edit), rewrite menu
  (shorter/funnier/formal), report. Tapping a received card opens the
  extension expanded with `selectedMessage` → full answer + “Ask a follow-up”. **Send** calls
  `sendText` straight from the user's tap (iOS only allows a direct send right after a touch) and
  falls back to `insertText` on `sendWithoutRecentInteraction`.
* **Widgets/** – `NimbusLiveActivity` (lock screen + Dynamic Island while thinking/writing),
  `AskNimbusControl` (Control Center / Lock Screen / Action Button control that opens the app
  to a new question).
