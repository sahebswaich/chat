#!/usr/bin/env bash
# Nimbus — one-time setup on your Mac.
#
#   ./scripts/setup-mac.sh
#
# 1. checks Xcode and Node, 2. asks for your Apple Team ID, 3. deploys the Nimbus server to your
# Cloudflare account with your Claude API key, 4. points the Xcode project at it, 5. makes your
# invite code (and one for Apple's TestFlight reviewer), 6. test-builds and opens Xcode.
# Safe to re-run: it remembers your answers and redeploys the server code.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
dim() { printf '\033[2m%s\033[0m\n' "$*"; }
ok() { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
die() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1;35m▸ %s\033[0m\n' "$*"; }
# ask VAR "Question" "default"
ask() {
  local __var=$1 __q=$2 __def=${3:-} __ans
  if [ -n "$__def" ]; then read -r -p "  $__q [$__def]: " __ans; else read -r -p "  $__q: " __ans; fi
  [ -n "$__ans" ] || __ans=$__def
  printf -v "$__var" '%s' "$__ans"
}
setting() { [ -f Config/Local.xcconfig ] && sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" Config/Local.xcconfig | tail -1 | tr -d '[:space:]' || true; }

bold "☁️✨ Nimbus setup"
dim "Takes about 10 minutes. Press Enter to accept a [default]."

# ---------------------------------------------------------------------------------------------
step "1/6  Checking your Mac"
[ "$(uname)" = "Darwin" ] || die "Run this on your Mac."
command -v xcodebuild >/dev/null || die "Install Xcode 26 or newer from the App Store, open it once, then re-run."
# `|| true`: with pipefail a failing xcodebuild (Command Line Tools only, license not accepted)
# would otherwise end the script silently here instead of showing the message below.
XCODE_MAJOR=$(xcodebuild -version 2>/dev/null | sed -n 's/^Xcode \([0-9]*\).*/\1/p' || true)
[ -n "$XCODE_MAJOR" ] || die "xcodebuild isn't working. Open Xcode once (accept the license), or run: sudo xcode-select -s /Applications/Xcode.app"
[ "$XCODE_MAJOR" -ge 26 ] || die "Xcode $XCODE_MAJOR found — Nimbus needs Xcode 26 or newer (App Store requirement)."
ok "Xcode $(xcodebuild -version | head -1 | cut -d' ' -f2)"

if ! command -v node >/dev/null; then
  if command -v brew >/dev/null; then
    warn "Node.js isn't installed. Installing it with Homebrew…"
    brew install node
  else
    die "Install Node.js 22+ from https://nodejs.org (LTS), then re-run."
  fi
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
[ "$NODE_MAJOR" -ge 22 ] || die "Node $(node -v) is too old — install Node 22+ (brew upgrade node, or nodejs.org)."
ok "Node $(node -v)"

# ---------------------------------------------------------------------------------------------
step "2/6  Apple developer account"
dim "Your Team ID is on https://developer.apple.com/account → Membership details (10 characters)."
TEAM_ID=$(setting DEVELOPMENT_TEAM)
while :; do
  ask TEAM_ID "Team ID" "$TEAM_ID"
  TEAM_ID=$(printf '%s' "$TEAM_ID" | tr '[:lower:]' '[:upper:]')
  printf '%s' "$TEAM_ID" | grep -Eq '^[A-Z0-9]{10}$' && break
  warn "That doesn't look like a Team ID (10 letters/numbers)."
done
DEFAULT_BUNDLE=$(setting NIMBUS_BUNDLE_ID); [ -n "$DEFAULT_BUNDLE" ] || DEFAULT_BUNDLE="com.sahebswaich.nimbus"
dim "The bundle ID must be unique on the App Store; change it if Xcode says it's taken."
while :; do
  ask BUNDLE_ID "Bundle ID" "$DEFAULT_BUNDLE"
  printf '%s' "$BUNDLE_ID" | grep -Eq '^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$' && break
  warn "Use reverse-DNS letters, numbers and dots, like com.yourname.nimbus"
done
ok "Team $TEAM_ID · $BUNDLE_ID"

# ---------------------------------------------------------------------------------------------
step "3/6  Nimbus server (Cloudflare, free plan)"
cd "$ROOT/server"
dim "Installing server tools…"
npm ci --silent --no-audit --no-fund >/dev/null 2>&1 || npm install --silent --no-audit --no-fund
# `whoami --json` exits non-zero when not signed in. (Grepping the text output under pipefail
# is flaky: grep -q exits on the first match and wrangler can then fail writing the rest.)
if ! npx wrangler whoami --json >/dev/null 2>&1; then
  dim "A browser window opens to sign in to Cloudflare (create a free account if you need one)."
  npx wrangler login
fi
ok "Signed in to Cloudflare"

ADMIN_FILE="$ROOT/server/.nimbus-admin.json"
SERVER_URL=""
ADMIN_TOKEN=""
if [ -f "$ADMIN_FILE" ]; then
  SERVER_URL=$(node -p 'require(process.argv[1]).url || ""' "$ADMIN_FILE" 2>/dev/null || true)
  ADMIN_TOKEN=$(node -p 'require(process.argv[1]).adminToken || ""' "$ADMIN_FILE" 2>/dev/null || true)
fi

SECRETS_DIR=$(mktemp -d)
trap 'rm -rf "$SECRETS_DIR"' EXIT
SECRETS_FILE="$SECRETS_DIR/secrets.env"
DEPLOY_ARGS=()
REUSED_SERVER=0
if [ -n "$SERVER_URL" ] && [ -n "$ADMIN_TOKEN" ]; then
  REUSED_SERVER=1
  ok "Found your server: $SERVER_URL (redeploying the latest code)"
  # New tables first, so new code never runs against an old schema (a no-op when up to date).
  CI=true npx wrangler d1 migrations apply nimbus --remote >/dev/null 2>&1 || true
else
  dim "Nimbus answers with your Claude API key. Get one at https://console.anthropic.com → API Keys."
  dim "(It's separate from a claude.ai subscription; you pay per use, about a cent per answer.)"
  ANTHROPIC_API_KEY=""
  while :; do
    read -r -s -p "  Claude API key (hidden): " ANTHROPIC_API_KEY; echo
    case "$ANTHROPIC_API_KEY" in sk-ant-*) break ;; *) warn "Claude API keys start with sk-ant-" ;; esac
  done
  ask SUPPORT_EMAIL "Contact email shown in the app (for App Review)" "$(git config user.email 2>/dev/null || true)"
  ADMIN_TOKEN=$(openssl rand -hex 32)
  umask 077
  {
    printf 'ANTHROPIC_API_KEY=%s\n' "$ANTHROPIC_API_KEY"
    printf 'ADMIN_TOKEN=%s\n' "$ADMIN_TOKEN"
    # Optional; an empty secret is left out rather than uploaded as "".
    if [ -n "$SUPPORT_EMAIL" ]; then printf 'SUPPORT_EMAIL=%s\n' "$SUPPORT_EMAIL"; fi
  } > "$SECRETS_FILE"
  unset ANTHROPIC_API_KEY
  DEPLOY_ARGS=(--secrets-file "$SECRETS_FILE")
fi

dim "Deploying…"
DEPLOY_LOG="$SECRETS_DIR/deploy.log"
DEPLOY_OK=1
npx wrangler deploy ${DEPLOY_ARGS[@]+"${DEPLOY_ARGS[@]}"} >"$DEPLOY_LOG" 2>&1 || DEPLOY_OK=0
rm -f "$SECRETS_FILE"
grep -Ev '^[[:space:]]*$' "$DEPLOY_LOG" | tail -15 || true
if [ "$DEPLOY_OK" = 0 ]; then
  if grep -q "workers.dev subdomain" "$DEPLOY_LOG"; then
    die "Your Cloudflare account needs a workers.dev subdomain first: open the dash.cloudflare.com link above, pick a name, then re-run ./scripts/setup-mac.sh"
  fi
  if [ "$REUSED_SERVER" = 1 ] && grep -q "required secrets have not been set" "$DEPLOY_LOG"; then
    die "Your server's secrets are gone (was the Worker deleted?). Delete server/.nimbus-admin.json and re-run ./scripts/setup-mac.sh"
  fi
  die "The deploy failed — see the messages above, then re-run ./scripts/setup-mac.sh"
fi
# The Worker's own URL is printed on a line by itself after "Deployed nimbus triggers".
NEW_URL=$(grep -E '^[[:space:]]*https://[A-Za-z0-9.-]+\.workers\.dev[[:space:]]*$' "$DEPLOY_LOG" | head -1 | tr -d '[:space:]' || true)
[ -n "$NEW_URL" ] && SERVER_URL=$NEW_URL
[ -n "$SERVER_URL" ] || die "Couldn't find the server URL in the deploy output above."
# Saved right away so a re-run after a later failure reuses this server instead of asking again.
printf '{\n  "url": "%s",\n  "adminToken": "%s"\n}\n' "$SERVER_URL" "$ADMIN_TOKEN" > "$ADMIN_FILE"
chmod 600 "$ADMIN_FILE"
dim "Updating the database…"
CI=true npx wrangler d1 migrations apply nimbus --remote >/dev/null
for _ in 1 2 3 4 5 6; do
  curl -fsS "$SERVER_URL/health" >/dev/null 2>&1 && break
  sleep 3
done
curl -fsS "$SERVER_URL/health" >/dev/null 2>&1 && ok "Server is live at $SERVER_URL" || warn "Server deployed but /health isn't answering yet — give it a minute."
API_HOST=${SERVER_URL#https://}
cd "$ROOT"

# ---------------------------------------------------------------------------------------------
step "4/6  Configuring the Xcode project"
cat > Config/Local.xcconfig <<EOF
// Written by scripts/setup-mac.sh — your personal settings (git-ignored).
DEVELOPMENT_TEAM = $TEAM_ID
NIMBUS_BUNDLE_ID = $BUNDLE_ID
NIMBUS_API_HOST = $API_HOST
EOF
ok "Config/Local.xcconfig → team $TEAM_ID, server $API_HOST"

# ---------------------------------------------------------------------------------------------
step "5/6  Invite codes"
MAKE_INVITES=y
# A re-run reuses the server, and the codes made the first time still work.
[ "$REUSED_SERVER" = 1 ] && ask MAKE_INVITES "Make new invite codes (y/n)" "n"
case "$MAKE_INVITES" in
  [yY]*)
    ask OWNER_NAME "Your name (shown to you in the app)" "$(id -F 2>/dev/null || whoami)"
    (cd server && npm run -s admin -- invite "$OWNER_NAME") || warn "Couldn't create your invite — run: cd server && npm run admin -- invite \"$OWNER_NAME\""
    dim "And one for Apple's TestFlight reviewer (paste it in App Store Connect → TestFlight → Test Information):"
    (cd server && npm run -s admin -- invite "App Review" --uses 5) || true
    ;;
  *) dim "Skipped. See your codes with: cd server && npm run admin -- invites" ;;
esac

# ---------------------------------------------------------------------------------------------
step "6/6  Test build"
if xcodebuild -project Nimbus.xcodeproj -scheme Nimbus -configuration Debug \
     -destination 'generic/platform=iOS Simulator' -derivedDataPath build/setup-check \
     CODE_SIGNING_ALLOWED=NO -quiet build; then
  ok "Nimbus builds"
else
  warn "The test build failed — open Xcode to see the errors. (If it says iOS 26 isn't installed: xcodebuild -downloadPlatform iOS)"
fi
open Nimbus.xcodeproj

bold ""
bold "All set. Next:"
cat <<EOF
  1. Xcode is open. Sign in once under Xcode → Settings → Accounts (your Apple ID).
  2. Plug in your iPhone, pick it in the bar at the top, press ⌘R.
     First time only: on the iPhone, Settings → Privacy & Security → Developer Mode → On.
  3. Open Nimbus on your iPhone and enter your invite code from step 5.
  4. In Messages, open any chat → + → More → drag Nimbus up. Done!

  Share with friends (TestFlight):
  • App Store Connect → Apps → + → New App · iOS · bundle ID $BUNDLE_ID
  • ./scripts/testflight.sh                       (archives + uploads)
  • TestFlight tab → External Testing → add a group, add the build, invite friends by email
    Privacy policy URL: $SERVER_URL/privacy
  • Give each friend a code:  cd server && npm run admin -- invite "Their Name"
EOF
