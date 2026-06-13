# YouTubeDiscordPresence — Windows host (script installer)

A lightweight, **no-admin** alternative to the upstream `YTDPsetup.msi`. It does
the same registration the MSI does, but per-user: copies `YTDPwin.exe` into
`%LOCALAPPDATA%\YouTubeDiscordPresence`, writes the native-messaging manifest,
and registers the host under `HKCU` for Chrome / Edge / Brave.

The browser extension is unchanged — install it from the Chrome Web Store.

## Files

| File | Purpose |
|------|---------|
| `install.ps1` | Installs `YTDPwin.exe` and registers the native host (no admin) |
| `uninstall.ps1` | Removes the registry keys and the install folder |

## Install

1. Put `YTDPwin.exe` (from the release, or `NodeHost/src/YTDPwin.exe`) in the
   same folder as `install.ps1`.
2. Right-click `install.ps1` → **Run with PowerShell**, or:

   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```

3. Fully restart your browser and the Discord desktop app, then play a
   YouTube / YouTube Music tab.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## Notes

- **Already have the upstream MSI installed?** You don't need this — just replace
  `C:\Program Files\YouTubeDiscordPresence\YTDPwin.exe` with the new exe.
- This installs to `%LOCALAPPDATA%` and registers in `HKCU`, so it never needs
  administrator rights. If you later run the upstream MSI, its machine-wide
  registration will point the browser at the `Program Files` copy instead.
- The manifest is registered for Chrome, Edge, and Brave. Other Chromium
  browsers can be added by creating the equivalent
  `HKCU:\Software\<Vendor>\...\NativeMessagingHosts\com.ytdp.discord.presence` key.
