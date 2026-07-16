#!/bin/bash
# R9 Capture — one-line installer
#   curl -fsSL https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.sh | bash
set -euo pipefail
REPO="XPro-Gamer-Rhine/R9-Capture-app"
APP_NAME="R9 Capture.app"
DEST="/Applications/$APP_NAME"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The /releases/latest/download/ redirect needs no API call, so it never
# hits GitHub's anonymous rate limit.
URL="https://github.com/$REPO/releases/latest/download/R9-Capture.tar.gz"

echo "==> Downloading the latest R9 Capture..."
curl -fSL --retry 3 "$URL" -o "$TMP/app.tar.gz"
tar -xzf "$TMP/app.tar.gz" -C "$TMP"

echo "==> Installing to /Applications..."
if pgrep -x "R9 Capture" >/dev/null 2>&1; then
  osascript -e 'tell application "R9 Capture" to quit' >/dev/null 2>&1 || true
  sleep 1
  pkill -x "R9 Capture" >/dev/null 2>&1 || true
  sleep 1
fi
rm -rf "$DEST"
cp -R "$TMP/$APP_NAME" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

echo "==> Launching..."
open "$DEST"
echo ""
echo "R9 Capture is installed. It lives in the menu bar (the ◉ icon)."
echo "First capture will ask for Screen Recording permission —"
echo "allow it in System Settings, then reopen the app."
