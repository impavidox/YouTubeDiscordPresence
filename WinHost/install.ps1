<#
  YouTubeDiscordPresence - Windows native host installer (no admin required)

  Does what the upstream MSI's registration step does, per-user:
    1. Copies YTDPwin.exe into %LOCALAPPDATA%\YouTubeDiscordPresence
    2. Writes the native-messaging manifest (main.json) next to it
    3. Registers the host under HKCU for Chrome / Edge / Brave

  Run:  right-click > "Run with PowerShell"
   or:  powershell -ExecutionPolicy Bypass -File install.ps1
#>
$ErrorActionPreference = "Stop"

$HostName  = "com.ytdp.discord.presence"
$ExtOrigin = "chrome-extension://hnmeidgkfcbpjjjpmjmpehjdljlaeaaa/"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Locate the exe: next to this script first, then the repo build output.
$exe = $null
foreach ($c in @("$ScriptDir\YTDPwin.exe", "$ScriptDir\..\NodeHost\src\YTDPwin.exe")) {
    if (Test-Path $c) { $exe = (Resolve-Path $c).Path; break }
}
if (-not $exe) {
    Write-Error "YTDPwin.exe not found. Put it next to this script, then re-run."
    exit 1
}

# Per-user install location (no admin needed).
$installDir = Join-Path $env:LOCALAPPDATA "YouTubeDiscordPresence"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

$destExe = Join-Path $installDir "YTDPwin.exe"
Copy-Item -Path $exe -Destination $destExe -Force
Write-Host "Installed: $destExe"

# Write main.json. Backslashes must be escaped for JSON, and we write UTF-8
# without a BOM so Chrome parses it cleanly.
$manifestPath = Join-Path $installDir "main.json"
$escapedExe   = $destExe -replace '\\', '\\'
$manifestJson = @"
{
    "name": "$HostName",
    "description": "Component of the YouTubeDiscordPresence extension that allows the usage of native messaging.",
    "path": "$escapedExe",
    "type": "stdio",
    "allowed_origins": [
        "$ExtOrigin"
    ]
}
"@
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, (New-Object System.Text.UTF8Encoding $false))

# Register the host for each Chromium-family browser (HKCU = per-user).
$browsers = [ordered]@{
    "Chrome" = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
    "Edge"   = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName"
    "Brave"  = "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\$HostName"
}
foreach ($name in $browsers.Keys) {
    $key = $browsers[$name]
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name "(default)" -Value $manifestPath
    Write-Host "  registered for $name"
}

Write-Host ""
Write-Host "Done. Fully restart your browser and the Discord desktop app,"
Write-Host "then play a YouTube / YouTube Music tab."
