#!/bin/bash
# R9 Capture — one-line installer
#   curl -fsSL https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.sh | bash
set -euo pipefail
REPO="XPro-Gamer-Rhine/R9-Capture-app"
APP_NAME="R9 Capture.app"
DEST="/Applications/$APP_NAME"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Fetching the latest R9 Capture release..."
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
      grep browser_download_url | grep tar.gz | head -1 | cut -d'"' -f4)
[ -n "$URL" ] || { echo "Could not find a release download."; exit 1; }

echo "==> Downloading..."
curl -fsSL "$URL" -o "$TMP/app.tar.gz"
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
