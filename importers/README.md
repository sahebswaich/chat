# Importers — get iCloud Mail, iCloud Drive, ChatGPT and claude.ai into reach

Claude cloud sessions read Google Drive through the Drive connector, but they can't reach
iCloud or the ChatGPT/claude.ai apps: the session's network policy blocks those hosts
(`imap.mail.me.com`, `www.icloud.com`, `setup.icloud.com` were all refused). These are the
permanent routes, fastest first.

## 0. Fastest: link your Mac to the session (computer use)

1. Claude desktop app on the Mac → **Settings → This computer → Computer use: on**.
2. In the Claude chat composer: **+ → Devices →** pick the Mac, then send a message.

The session can then open Mail, Finder (iCloud Drive), ChatGPT and claude.ai on your Mac
directly. Nothing below is needed for one-off reads; the routes below make it automatic.

## 1. iCloud Drive folders → Google Drive (set once, syncs forever)

Google Drive for desktop on the Mac → **Settings (gear) → Preferences → My Mac → Add folder**
→ pick each iCloud Drive folder (the AI workspace folders, the OCC downloads, `~/Downloads`)
→ **Sync with Google Drive** → Done. They now mirror into Drive under *Computers → My Mac*,
and every Claude session can read them.

## 2. iCloud Mail → Google Drive (hourly, on the Mac)

1. Make an app-specific password: [account.apple.com](https://account.apple.com) →
   Sign-In and Security → App-Specific Passwords → `+` (name it "imap").
2. Store it in the Keychain (it prompts for the password; nothing is typed on the command line):
   ```bash
   security add-generic-password -a you@icloud.com -s icloud-imap -w
   ```
3. Test once:
   ```bash
   ICLOUD_EMAIL=you@icloud.com python3 importers/icloud_mail.py \
     --match smollen --out "$HOME/Library/CloudStorage/GoogleDrive-swaichsaheb@gmail.com/My Drive/AI Inbox/iCloud Mail"
   ```
4. Make it hourly: edit the email in `importers/com.saheb.icloud-mail.plist`, copy it to
   `~/Library/LaunchAgents/`, then `launchctl load ~/Library/LaunchAgents/com.saheb.icloud-mail.plist`.

Add more `--match` terms (names, companies, "american perpetual", "greyline") to pull more threads.

### Or: straight from a Claude cloud session

In the cloud environment's settings (environment menu in the session title bar → **Edit**):
add `imap.mail.me.com` under **Network access → Allowed domains**, and add `ICLOUD_EMAIL`
and `ICLOUD_APP_PASSWORD` as secrets. A new session can then run
`python3 importers/icloud_mail.py --match smollen --out corpus/icloud-mail`. (The session
proxy may only tunnel web ports; if port 993 is still refused, use the Mac route above.)

## 3. ChatGPT and claude.ai history

**Every conversation (export):**
- ChatGPT: Settings → Data controls → **Export data**.
- claude.ai: Settings → Privacy → **Export data**.

Both email a .zip. Put it in Drive (`AI Inbox/exports/`) and say so, or run:
```bash
python3 importers/chat_exports.py ~/Downloads/<export>.zip --out "AI Inbox/ChatGPT" \
  --match crypto --match perp --match prime --match breakout
```

**Right now, natively:** open a new claude.ai chat (with past-chat search on) and paste the
prompt in `importers/claude_ai_harvest_prompt.md`. It makes Claude search your past chats and
write them into one Google Doc in Drive, which these sessions then read.
