#!/usr/bin/env bash
#
# YouTubeDiscordPresence - macOS native host installer
#
# Registers the YTDPmac binary as the Chrome native-messaging host
# "com.ytdp.discord.presence" for every Chromium-family browser found.
#
# On macOS the host is registered by dropping a manifest JSON into each
# browser's NativeMessagingHosts directory. Unlike Windows, the manifest
# "path" MUST be an absolute path, so this script records wherever the
# binary currently lives -- keep it in a permanent folder before running.
#
# Usage:
#   ./install.sh [path-to-YTDPmac]
#
set -euo pipefail

HOST_NAME="com.ytdp.discord.presence"
EXT_ORIGIN="chrome-extension://hnmeidgkfcbpjjjpmjmpehjdljlaeaaa/"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the binary: explicit arg first, then a couple of sensible defaults.
BIN="${1:-}"
if [[ -z "$BIN" ]]; then
  for c in "$SCRIPT_DIR/YTDPmac" "$SCRIPT_DIR/../NodeHost/dist/YTDPmac"; do
    if [[ -f "$c" ]]; then BIN="$c"; break; fi
  done
fi

if [[ -z "$BIN" || ! -f "$BIN" ]]; then
  echo "error: YTDPmac binary not found." >&2
  echo "Place YTDPmac next to this script, or pass its path:" >&2
  echo "    ./install.sh /full/path/to/YTDPmac" >&2
  exit 1
fi

# Resolve to an absolute path (required by macOS native messaging).
BIN="$(cd "$(dirname "$BIN")" && pwd)/$(basename "$BIN")"
echo "Binary: $BIN"

# 1. Make it executable.
chmod +x "$BIN"

# 2. Clear the Gatekeeper quarantine flag (present if downloaded via a browser).
#    Without this, macOS refuses to exec an unsigned binary.
xattr -dr com.apple.quarantine "$BIN" 2>/dev/null || true

# 3. Write the manifest into every installed Chromium-family browser.
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

write_manifest() {
  local nmh="$1/NativeMessagingHosts"
  mkdir -p "$nmh"
  cat > "$nmh/$HOST_NAME.json" <<EOF
{
    "name": "$HOST_NAME",
    "description": "Component of the YouTubeDiscordPresence extension that allows the usage of native messaging.",
    "path": "$BIN",
    "type": "stdio",
    "allowed_origins": [
        "$EXT_ORIGIN"
    ]
}
EOF
  echo "  installed -> $nmh/$HOST_NAME.json"
}

installed_any=0
for d in "${BROWSER_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    write_manifest "$d"
    installed_any=1
  fi
done

if [[ "$installed_any" -eq 0 ]]; then
  echo "No Chromium-family browser profile detected; installing for Google Chrome by default."
  write_manifest "$APP_SUPPORT/Google/Chrome"
fi

echo
echo "Done."
echo "Next: fully quit and reopen your browser, make sure the Discord desktop app"
echo "is running, then play a YouTube / YouTube Music tab."
