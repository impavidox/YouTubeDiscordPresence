<#
  YouTubeDiscordPresence - Windows native host uninstaller
  Removes the HKCU registry registrations and the per-user install folder.

  Run:  powershell -ExecutionPolicy Bypass -File uninstall.ps1
#>
$ErrorActionPreference = "Stop"

$HostName = "com.ytdp.discord.presence"

$keys = @(
    "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
    "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName"
    "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName"
)
foreach ($key in $keys) {
    if (Test-Path $key) {
        Remove-Item -Path $key -Force -Recurse
        Write-Host "removed registry key: $key"
    }
}

$installDir = Join-Path $env:LOCALAPPDATA "YouTubeDiscordPresence"
if (Test-Path $installDir) {
    Remove-Item -Path $installDir -Recurse -Force
    Write-Host "removed install folder: $installDir"
}

Write-Host "Done. The native host is no longer registered."
