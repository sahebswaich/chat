# Nimbus ☁️✨

**An AI in your iMessage + menu.** Tap **+ → Nimbus** in any conversation, ask anything, and
send the answer as a normal text bubble or as a Nimbus card. It's also a full chat app on
iPhone and iPad.

Friends get in with an **invite code** and install through **TestFlight**. Everyone's
questions run through *your* Claude API key, which stays on the Nimbus server and is never
shipped inside the app.

| | |
|---|---|
| **iPhone / iPad** | iMessage app in the + drawer · full chat app · Siri / Action Button / Spotlight “Ask Nimbus” · Control Center button · Live Activity in the Dynamic Island while it thinks |
| **Server** | Cloudflare Worker · invite codes · per-person daily limits · streams Claude answers |

## Setup on your Mac (one time, about 20 minutes)

You need:
* **Xcode 26 or newer**, signed in with your Apple ID (Xcode → Settings → Accounts).
* An **Apple Developer Program** membership ($99/yr) for TestFlight.
* A **Claude API key** from [platform.claude.com](https://platform.claude.com) → Settings → API keys.
  This is separate from a claude.ai subscription. You pay per use, usually 1–3¢ per answer.
* A **Cloudflare** account ([dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)).
  Free works for short iMessage answers. Long answers in the app can hit the free plan's 10 ms
  CPU limit, which the $5/month Workers Paid plan removes (no code change).

Then run:

```bash
git clone https://github.com/sahebswaich/chat.git ~/chat
cd ~/chat
./scripts/setup-mac.sh
```

The script asks for your Team ID and Claude key. It deploys the server, configures the Xcode
project, makes your first invite code, and opens Xcode. Then:

1. Plug in your iPhone, pick it as the run destination, and press **⌘R**.
2. In Messages, open any chat → **+** → **More** → drag **Nimbus** up into the list.
3. Paste your invite code in Nimbus. That's it.

## Share it with friends (TestFlight, invite only)

1. **Create the app record once**: [App Store Connect](https://appstoreconnect.apple.com) →
   Apps → **+** → New App. Platform iOS, bundle ID `com.sahebswaich.nimbus` (or yours),
   and any unique name, e.g. “Nimbus Chat AI”.
2. **Upload a build**: `./scripts/testflight.sh` (archives and uploads the iOS build).
3. **Fill in Test Information** (TestFlight tab → Test Information): a short beta description,
   your feedback email, privacy policy URL `https://<your-server>/privacy`, and under **Beta App
   Review Information → notes** the **App Review** invite code that `setup-mac.sh` printed
   (“Open Nimbus, enter this invite code, tick the consent box”). Apple's reviewer needs it
   to get in.
4. **Invite**: create an internal group first (Apple requires one; add yourself), then
   External Testing → **+** group “Friends” → add the build → add testers by email (or a public
   link with a tester limit). The first build of each version goes through Beta App Review,
   usually within a day.
5. **Give each friend an invite code**:
   ```bash
   cd server && npm run admin -- invite "James"
   ```
   Send them the link it prints (`https://<your-server>/join/XXXX-XXXX`). It has the TestFlight
   button and an **Open Nimbus** button that signs them in.

Manage access: `npm run admin -- users`, `npm run admin -- revoke-user <id>`,
`npm run admin -- invites`. Everyone gets 200 answers a day by default (set `DAILY_LIMIT` in
`server/wrangler.jsonc`).

## Using it

**In Messages (iPhone/iPad):** **+ → Nimbus**.
* Tap the prompt bar and ask. The answer streams in with the typing dots you know.
* **Send** posts it as a regular text bubble that everyone can read.
* **Card** sends a Nimbus bubble with the question and answer. Friends with Nimbus can tap it to
  ask a follow-up; anyone reading on a Mac clicks it to open the answer as a web page.
* **Insert** drops the answer into the text field so you can edit it first.
* Long-press the answer to make it **shorter, funnier, more formal**, or to report it.
* Paste part of the conversation and pick **Reply for me**, **Explain**, or **Fact-check**.
  Nimbus only ever sees what you paste. Apple doesn't let iMessage apps read your chats.

**Siri / Action Button / Spotlight:** “Ask Nimbus …”. You can assign it to the Action Button in
Settings → Action Button → Shortcut.


## Repo

```
App/ MessagesExtension/ Widgets/ Shared/ Tests/       Swift 6 / SwiftUI (Xcode project: Nimbus.xcodeproj)
server/                                               Cloudflare Worker (TypeScript)
scripts/                                              setup-mac.sh, testflight.sh
.github/workflows/                                    CI: builds + tests iOS, tests server, optional TestFlight upload
docs/                                                 architecture & API contract
```

CI builds every push on GitHub's Mac runners. To upload to TestFlight from CI instead of your
Mac, add the secrets listed in [.github/workflows/testflight.yml](.github/workflows/testflight.yml).
