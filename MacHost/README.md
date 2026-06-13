# YouTubeDiscordPresence — macOS host

This is the macOS port of the desktop component (the Windows side ships
`YTDPwin.exe` registered via the registry/MSI). On macOS the same Node
program is compiled to a Mach-O binary named **`YTDPmac`** and registered as a
Chrome native-messaging host by dropping a manifest JSON into each browser's
`NativeMessagingHosts` directory.

The browser extension itself is unchanged — install it from the Chrome Web
Store exactly as on Windows.

## What's in this folder

| File | Purpose |
|------|---------|
| `installer/` | Sources for the double-click **`YTDPsetup.pkg`** installer (see below) |
| `install.sh` | Registers `YTDPmac` as the native host for all Chromium browsers found |
| `uninstall.sh` | Removes the manifests |

The compiled binary is produced at `NodeHost/dist/YTDPmac`.

## Install (recommended: the `.pkg`)

The easiest path for end users is the **`YTDPsetup.pkg`** installer (the macOS
counterpart of the Windows `.msi`). It:

- ships **both** CPU slices and installs the one matching your Mac as
  `YTDPmac` in `/Library/Application Support/YouTubeDiscordPresence/` — Apple
  Silicon gets the **native arm64** build (no Rosetta), Intel gets x86_64,
- registers the native-messaging host for the logged-in user's Chromium-family
  browsers automatically (postinstall script), and
- bundles `install.sh` / `uninstall.sh` next to the binary for later use.

> **Unsigned package.** There's no Apple Developer ID, so Gatekeeper will block a
> double-click of a downloaded `.pkg` ("Apple cannot check it for malicious
> software"). **Right-click the `.pkg` → Open**, or go to **System Settings →
> Privacy & Security → Open Anyway**. The bundled binary is ad-hoc signed and
> the installer clears its quarantine flag, so it runs once installed.

After installing: fully quit and reopen your browser, make sure the **Discord
desktop app** is running, then play a YouTube / YouTube Music tab.

To uninstall, run `uninstall.sh` from
`/Library/Application Support/YouTubeDiscordPresence/`, then delete that folder
(`sudo rm -rf "/Library/Application Support/YouTubeDiscordPresence"`).

## Build (only needed if you want to recompile)

From `NodeHost/`:

```bash
npm install
npm run compile-mac          # -> NodeHost/dist/YTDPmac        (node18-macos-x64)
npm run compile-mac-arm64    # -> NodeHost/dist/YTDPmac-arm64  (node18-macos-arm64)
```

Two thin binaries, one per CPU. `pkg` can't make a working *universal* binary:
it bakes the payload's absolute file offset into each executable, so `lipo`-ing
the slices together relocates them and the runtime reads the wrong offset.
The `.pkg` ships both and installs the right one (see above).

The **arm64** slice must be built **on a Mac** — `pkg` has no prebuilt arm64
base for cross-compilation from Windows (it falls back to building Node from
source, which fails off-platform). The x86_64 slice cross-compiles fine and
also runs on Apple Silicon under Rosetta 2.

## Build the installer (`.pkg`)

`installer/build-pkg.sh` produces the double-click `YTDPsetup.pkg` **from
scratch** — it clean-recompiles **both** slices, ad-hoc signs them, then runs
`pkgbuild` + `productbuild`:

```bash
MacHost/installer/build-pkg.sh          # -> MacHost/installer/dist/YTDPsetup.pkg
SKIP_COMPILE=1 MacHost/installer/build-pkg.sh   # reuse existing NodeHost/dist/YTDPmac{,-arm64}
```

| Path | Purpose |
|------|---------|
| `installer/build-pkg.sh` | The from-scratch build script (builds x86_64 + arm64) |
| `installer/scripts/postinstall` | Runs as root after install; keeps the slice matching the Mac's hardware (`sysctl hw.optional.arm64`) as `YTDPmac`, then registers the host for the console user |
| `installer/distribution.xml` | `productbuild` layout (title, welcome/license/conclusion panes, system-volume install) |
| `installer/resources/` | `welcome.html` / `conclusion.html` shown in the installer UI |

The resulting `.pkg` is git-ignored (like `YTDPwin.exe` / the `.msi`) — attach it
to a GitHub Release. It is **unsigned** (no Developer ID); see the Gatekeeper
note above.

## Install (manual / advanced)

You can also register the binary by hand instead of using the `.pkg`:

1. Put `YTDPmac` in a **permanent** folder (the manifest hard-codes its
   absolute path — don't run it from `~/Downloads` and then delete it).
   A good spot: `~/Applications/YouTubeDiscordPresence/`.
2. Run the installer (it auto-finds the binary next to itself or in
   `../NodeHost/dist/`):

   ```bash
   chmod +x install.sh
   ./install.sh                       # or: ./install.sh /full/path/to/YTDPmac
   ```

3. Fully quit and reopen your browser, make sure the **Discord desktop app**
   is running, then play a YouTube / YouTube Music tab.

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

(Delete the `YTDPmac` binary afterward if you want.)

## Troubleshooting

**Apple Silicon (M1/M2/M3…):** the `.pkg` installs the **native arm64** slice,
so Rosetta 2 is **not** needed. You only need Rosetta if you manually run the
**x86_64** binary (`NodeHost/dist/YTDPmac`) on Apple Silicon — to install it:

```bash
softwareupdate --install-rosetta --agree-to-license
```

**"cannot be opened because the developer cannot be verified" / it silently
doesn't connect:** the binary is unsigned. `install.sh` already strips the
quarantine flag; if it's still blocked, add an ad-hoc signature:

```bash
codesign --force --sign - /full/path/to/YTDPmac
xattr -dr com.apple.quarantine /full/path/to/YTDPmac
```

**Nothing happens at all:** confirm the manifest landed in the right place for
your browser, e.g. for Chrome:

```bash
cat "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.ytdp.discord.presence.json"
```

The `path` inside must be the correct absolute path to `YTDPmac`, and that file
must be executable (`chmod +x`).

## How this differs from the Windows build

- **Binary:** `YTDPmac` (Mach-O) instead of `YTDPwin.exe` (PE). No `resedit`
  version-stamping step — that's Windows-only.
- **Registration:** a manifest JSON in `~/Library/Application Support/<Browser>/NativeMessagingHosts/`
  with an **absolute** `path`, instead of a Windows registry key + MSI.
- **Discord IPC:** handled transparently by `discord-rpc` — Unix domain sockets
  (`$TMPDIR/discord-ipc-N`) on macOS vs. named pipes on Windows. No code change.
- **App logic (`app.js`):** identical. Only the packaging/registration differs.
