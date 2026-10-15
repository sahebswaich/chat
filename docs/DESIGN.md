# Nimbus — design

Nimbus should feel like it shipped with iOS 26: Liquid Glass, system fonts, and interaction
patterns people's hands already know. Nothing here needs explaining to a first-time user.

## Look

* **Palette:** indigo `#5856F6` → violet `#8B5CF6` → cyan `#22D3EE` (the "sky"). Asset colors
  `NimbusIndigo`, `NimbusCyan`, `AccentColor` (`#6C5CF6`, lighter in dark mode).
* **Material:** Liquid Glass (`.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)` /
  `.glassProminent`) for the prompt bar, chips and action bar. Content (answers) sits
  on plain backgrounds for legibility.
* **Type:** system font only. Answers use `.body`; the question echo uses `.callout` in
  `.secondary`; labels use `.caption.weight(.semibold)` with `.smallCaps()`.
* **Icon:** a cloud-shaped speech bubble with a sparkle on the sky gradient (dark and tinted
  variants included).

## Interaction patterns people already know

| Pattern | Where | Why it feels native |
|---|---|---|
| **Typing dots** (three dots pulsing in a gray bubble) | before the first word arrives | the universal "someone's typing" signal from Messages |
| **Glowing edge** (slowly rotating angular gradient stroke, sky colors) | around the answer while it streams | the Apple Intelligence / Siri glow means "AI is working" |
| **Blue ↑ send button** in a capsule field | composer | the Messages compose bar |
| **Long-press → menu** (Copy, Shorter, Funnier, More formal, Regenerate, Report) | any answer | the context-menu reflex |
| **Code boxes** that auto-advance and accept paste | invite code entry | 2FA / verification-code fields |
| **Pull down to dismiss**, swipe the card | expanded iMessage view | sheets everywhere |
| **Haptics:** selection tick on chips, soft tap on first word, success on finish, firm tap on send, error buzz on failure | everywhere (iOS) | `.sensoryFeedback` |
| **Dynamic Island** Live Activity: sparkle + "Thinking…" → "Answer ready" | iPhone app while an answer streams | the island is where "something is happening" lives |
| **Action Button / Control Center / Siri / Spotlight** "Ask Nimbus" | system | App Intents + a control |

## iMessage extension (the main event)

**Compact** (the + drawer panel, keyboard height):
```
 ✨ Nimbus                                  12/200 today
 ┌─────────────────────────────────────────────── ↑ ┐   ← tap = expand + focus keyboard
 │ Ask anything…                                     │
 └───────────────────────────────────────────────────┘
 [📋 Paste chat] [💬 Reply for me] [🧠 Explain] [✅ Fact-check]
 [😂 Funny] [📝 Summarize]
 Recent  ┌──────────┐ ┌──────────┐ ┌──────────┐            ← tap to resend / open
         │ nephilim │ │ dinner…  │ │ …        │
```
Typing a question needs the keyboard, which only shows in **expanded** mode, so the bar
expands the view. Chips that run on pasted text (Paste chat → Reply / Explain / Fact-check /
Summarize) work right in compact mode via `PasteButton`, so there's no paste-permission alert.

**Expanded:** a thread like Messages, with your question as a right-aligned sky-gradient bubble
and Nimbus's answer left-aligned with the glowing edge while streaming, plus the composer at the
bottom. Under the latest answer is a glass action bar:

`[ ↑ Send ]  [ ▢ Card ]  [ ✎ Insert ]  [ ⋯ ]`

* **Send** → `sendText` (a normal bubble everyone can read, on every device). Falls back to
  `insertText` if iOS refuses a direct send.
* **Card** → `MSMessage` with an `MSMessageTemplateLayout`: the card rendered to an image
  (`ImageRenderer`) with caption = question and subcaption = "Nimbus". Its URL is the server's card
  page, so people reading on a Mac or Watch click through to a web page.
* **Insert** → `insertText`, collapse, and let the person edit.

**Card image** (what the bubble shows): a "✨ NIMBUS" label, the question (secondary), and the
answer (up to 6 lines), with a hairline sky-gradient border on a light card. Tapping it opens the
extension expanded on the full answer with **Ask a follow-up**.

## iPhone app

* **Onboarding:** sky gradient, the icon floating with gentle parallax, "Your AI for iMessage",
  then the code boxes. `nimbus://join?code=…` deep links fill the code and redeem automatically.
* **Chat:** the same thread UI as the expanded extension, with Markdown answers, history saved in
  SwiftData, and the conversation list in a sidebar on iPad.
* **"Add Nimbus to Messages"** card: a three-step mini-animation of + → More → Nimbus.
* **Settings:** usage meter (glass ring), server host, sign out, privacy link.
