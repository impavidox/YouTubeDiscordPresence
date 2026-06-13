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
| `install.sh` | Registers `YTDPmac` as the native host for all Chromium browsers found |
| `uninstall.sh` | Removes the manifests |

The compiled binary is produced at `NodeHost/dist/YTDPmac`.

## Build (only needed if you want to recompile)

From `NodeHost/`:

```bash
npm install
npm run compile-mac        # -> NodeHost/dist/YTDPmac  (node18-macos-x64)
```

`YTDPmac` is built for **x86_64**. It runs natively on Intel Macs and under
Rosetta 2 on Apple Silicon (see troubleshooting if you're on an M-series Mac).
A native `arm64` build can't be cross-compiled from Windows — `pkg` has no
prebuilt arm64 base and falls back to compiling Node from source, which fails
off-platform. Build arm64 on a Mac with `pkg -t node18-macos-arm64`.

## Install

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

**Apple Silicon (M1/M2/M3…):** the binary is x86_64, so Rosetta 2 must be
present. It usually is, but to be sure:

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
