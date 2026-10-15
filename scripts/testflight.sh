#!/usr/bin/env bash
# Archive Nimbus (iPhone/iPad app + iMessage extension + widgets) and upload it to TestFlight.
#
#   ./scripts/testflight.sh
#
# Signing uses the Apple ID you're signed into in Xcode (Xcode → Settings → Accounts).
# To use an App Store Connect API key instead (Admin "Team key"), set:
#   ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxxxxxx-xxxx-... ASC_KEY_PATH=~/keys/AuthKey_XXXXXXXXXX.p8
#
# Before the first upload, create the app once in App Store Connect (Apps → + → New App) with the
# same bundle ID as Config/Local.xcconfig. Run the app on your iPhone from Xcode once first, too:
# that registers your device, which automatic signing needs.
set -euo pipefail
cd "$(dirname "$0")/.."

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
die() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[ -f Config/Local.xcconfig ] || die "Config/Local.xcconfig is missing — run ./scripts/setup-mac.sh first."
setting() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" Config/Local.xcconfig | tail -1 | tr -d '[:space:]'; }
TEAM_ID=$(setting DEVELOPMENT_TEAM)
BUNDLE_ID=$(setting NIMBUS_BUNDLE_ID)
API_HOST=$(setting NIMBUS_API_HOST)
[ -n "$TEAM_ID" ] || die "DEVELOPMENT_TEAM is empty in Config/Local.xcconfig."
[ -n "$API_HOST" ] || die "NIMBUS_API_HOST is empty in Config/Local.xcconfig."

# Build numbers must go up with every upload; a timestamp always does.
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%y%m%d.%H%M)}"
VERSION=$(sed -n 's/^MARKETING_VERSION[[:space:]]*=[[:space:]]*//p' Config/Base.xcconfig | tr -d '[:space:]')

AUTH=()
if [ -n "${ASC_KEY_ID:-}" ]; then
  [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ] || die "Set ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH together."
  KEY_PATH=$(cd "$(dirname "$ASC_KEY_PATH")" && pwd)/$(basename "$ASC_KEY_PATH")
  AUTH=(-authenticationKeyPath "$KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

pretty() { if command -v xcbeautify >/dev/null 2>&1; then xcbeautify; else grep -E "error|warning: .*(sign|profile)|ARCHIVE|EXPORT|Upload|\*\*" || true; fi; }

ARCHIVE=build/Nimbus.xcarchive
rm -rf "$ARCHIVE" build/export
mkdir -p build

bold "▸ Archiving Nimbus $VERSION ($BUILD_NUMBER) for $BUNDLE_ID — server $API_HOST"
set -o pipefail
xcodebuild archive \
  -project Nimbus.xcodeproj -scheme Nimbus -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" 2>&1 | tee build/archive.log | pretty
[ -d "$ARCHIVE" ] || die "Archive failed — see build/archive.log"

cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>upload</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>manageAppVersionAndBuildNumber</key><false/>
	<key>uploadSymbols</key><true/>
	<key>testFlightInternalTestingOnly</key><false/>
</dict>
</plist>
PLIST

bold "▸ Uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" -exportOptionsPlist build/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} 2>&1 | tee build/export.log | pretty

if grep -q "EXPORT SUCCEEDED\|Upload succeeded\|Uploaded" build/export.log; then
  bold "✓ Uploaded Nimbus $VERSION ($BUILD_NUMBER)."
  echo "  In 5–15 minutes it shows up in App Store Connect → your app → TestFlight."
  echo "  Add it to your 'Friends' external group; the first build goes through a quick Beta App Review."
else
  die "Upload didn't finish — see build/export.log. If it says the app record doesn't exist, create it in App Store Connect with bundle ID $BUNDLE_ID."
fi
