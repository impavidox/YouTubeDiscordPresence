#!/usr/bin/env bash
#
# Build YTDPsetup.pkg (the macOS installer) from scratch.
#
#   1. clean & recompile YTDPmac for BOTH arches
#        - node18-macos-x64    -> Intel
#        - node18-macos-arm64  -> Apple Silicon (native, no Rosetta)
#   2. ad-hoc sign + sanity-check each slice
#   3. stage both slices and pkgbuild a component pkg
#   4. productbuild the double-click distribution pkg
#
# pkg bakes the payload's absolute file offset into each binary, so a `lipo`
# universal binary does NOT work (the relocated slice reads the wrong offset).
# Instead we ship both thin binaries; the postinstall picks the one matching
# the Mac's hardware and renames it to YTDPmac.
#
# Output:  MacHost/installer/dist/YTDPsetup.pkg
#
# Env:
#   SKIP_COMPILE=1   reuse existing NodeHost/dist/YTDPmac{,-arm64} (skip step 1)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"      # MacHost/installer
REPO="$(cd "$HERE/../.." && pwd)"
NODEHOST="$REPO/NodeHost"

HOST_ID="com.ytdp.discord.presence.host"
VERSION="$(node -p "require('$NODEHOST/package.json').version")"

BUILD="$HERE/build"
PAYLOAD="$BUILD/payload"
RES="$BUILD/resources"
DIST="$HERE/dist"
BIN_X64="$NODEHOST/dist/YTDPmac"          # compile-mac output (x86_64)
BIN_ARM="$NODEHOST/dist/YTDPmac-arm64"    # compile-mac-arm64 output (arm64)

echo "==> YTDPsetup.pkg  (host component v$VERSION)"

rm -rf "$BUILD" "$DIST"
mkdir -p "$PAYLOAD" "$RES" "$DIST"

# 1. clean recompile of both slices -------------------------------------------
if [[ "${SKIP_COMPILE:-0}" == "1" ]]; then
  echo "==> SKIP_COMPILE=1: reusing existing slices"
else
  echo "==> compiling YTDPmac (x86_64 + arm64) from scratch"
  ( cd "$NODEHOST" && rm -rf node_modules dist && npm install \
      && npm run compile-mac && npm run compile-mac-arm64 )
fi
[[ -f "$BIN_X64" ]] || { echo "error: $BIN_X64 not found (build failed?)" >&2; exit 1; }
[[ -f "$BIN_ARM" ]] || { echo "error: $BIN_ARM not found (build failed?)" >&2; exit 1; }

# 2. ad-hoc sign + sanity check each slice ------------------------------------
echo "==> signing + checking slices"
for b in "$BIN_X64" "$BIN_ARM"; do
  codesign --force --sign - "$b"
  codesign --verify --verbose=2 "$b"
  file "$b"
done

# 3. stage payload (installs to /Library/Application Support/YouTubeDiscordPresence) --
# Both slices ship; the postinstall keeps the matching one as YTDPmac.
echo "==> staging payload"
cp "$BIN_X64"                   "$PAYLOAD/YTDPmac-x64"
cp "$BIN_ARM"                   "$PAYLOAD/YTDPmac-arm64"
cp "$REPO/MacHost/install.sh"   "$PAYLOAD/install.sh"
cp "$REPO/MacHost/uninstall.sh" "$PAYLOAD/uninstall.sh"
cp "$REPO/MacHost/README.md"    "$PAYLOAD/README.md"
chmod +x "$PAYLOAD/YTDPmac-x64" "$PAYLOAD/YTDPmac-arm64" "$PAYLOAD/install.sh" "$PAYLOAD/uninstall.sh"
# Clear extended attributes (notably com.apple.quarantine if the binary was
# ever downloaded). com.apple.provenance is system-managed and can't be removed
# -- it shows up as harmless ._ entries in the BOM but does NOT install as a
# visible file. The Mach-O code signature is embedded, not an xattr, so it
# survives this.
xattr -cr "$PAYLOAD" 2>/dev/null || true

# productbuild resources (welcome / license / conclusion panes)
cp "$HERE/resources/welcome.html"    "$RES/"
cp "$HERE/resources/conclusion.html" "$RES/"
cp "$REPO/LICENSE.txt"               "$RES/LICENSE.txt"

# 4. component pkg ------------------------------------------------------------
echo "==> pkgbuild (component)"
pkgbuild \
  --root "$PAYLOAD" \
  --identifier "$HOST_ID" \
  --version "$VERSION" \
  --install-location "/Library/Application Support/YouTubeDiscordPresence" \
  --scripts "$HERE/scripts" \
  "$BUILD/YTDPhost.pkg"

# 5. distribution (double-click) pkg ------------------------------------------
echo "==> productbuild (distribution)"
productbuild \
  --distribution "$HERE/distribution.xml" \
  --package-path "$BUILD" \
  --resources "$RES" \
  "$DIST/YTDPsetup.pkg"

echo
echo "==> done: $DIST/YTDPsetup.pkg"
ls -lh "$DIST/YTDPsetup.pkg"
pkgutil --check-signature "$DIST/YTDPsetup.pkg" 2>&1 | sed 's/^/    /' || true
