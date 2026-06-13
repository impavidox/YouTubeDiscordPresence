#!/usr/bin/env bash
#
# YouTubeDiscordPresence - macOS native host uninstaller
# Removes the com.ytdp.discord.presence manifest from every Chromium browser.
#
set -euo pipefail

HOST_NAME="com.ytdp.discord.presence"
APP_SUPPORT="$HOME/Library/Application Support"
BROWSER_DIRS=(
  "$APP_SUPPORT/Google/Chrome"
  "$APP_SUPPORT/Google/Chrome Beta"
  "$APP_SUPPORT/Google/Chrome Canary"
  "$APP_SUPPORT/Chromium"
  "$APP_SUPPORT/Microsoft Edge"
  "$APP_SUPPORT/BraveSoftware/Brave-Browser"
  "$APP_SUPPORT/Vivaldi"
)

removed=0
for d in "${BROWSER_DIRS[@]}"; do
  f="$d/NativeMessagingHosts/$HOST_NAME.json"
  if [[ -f "$f" ]]; then
    rm -f "$f"
    echo "removed -> $f"
    removed=1
  fi
done

if [[ "$removed" -eq 0 ]]; then
  echo "Nothing to remove."
else
  echo "Done. The native host is no longer registered."
fi
