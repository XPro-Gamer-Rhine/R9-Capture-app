<#
.SYNOPSIS
    Installs R9 Capture on Windows.

.DESCRIPTION
    The Windows counterpart of the Mac's curl one-liner:

        irm https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.ps1 | iex

    Downloads the latest release installer, runs it silently and starts the
    app. No administrator rights are needed: R9 Capture installs per-user and
    needs no driver, no system effect and no permission prompt — screen
    capture, the microphone and the global keys are all things a normal
    Windows program may simply do.

    Re-running upgrades in place. Settings live in %APPDATA%\R9 Capture and
    are never touched.

.PARAMETER Version
    Install a specific release tag instead of the latest.

.PARAMETER FromFile
    Install a setup .exe already on disk, for testing a local build.
#>
[CmdletBinding()]
param(
    [string] $Version,
    [string] $FromFile
)

# The whole install runs inside a function on purpose. This script is meant to
# be pasted as `irm ... | iex`, which executes in the caller's own session --
# so setting strict mode and $ErrorActionPreference at script level would leave
# the user's PowerShell window in that state long after the install finished,
# and their next typo would become a terminating error. Inside a function both
# are scoped to the install and go away with it.
function Invoke-R9CaptureInstall {
    param(
        [string] $Version,
        [string] $FromFile
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $Owner = 'XPro-Gamer-Rhine'
    $Repo  = 'R9-Capture-app'
    $AppName = 'R9 Capture'

    function Say([string] $Text, [string] $Color = 'Cyan') {
        Write-Host $Text -ForegroundColor $Color
    }

    Say ''
    Say "$AppName installer"
    Say ''

    # TLS 1.2 for Windows PowerShell 5.1, whose default is too old for GitHub.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # --- what the machine has to have ---------------------------------------
    #
    # Windows.Graphics.Capture, which is how every frame is taken, arrived in
    # Windows 10 1903. Older builds install fine and then cannot do the only
    # thing the app is for, so they are told before anything is downloaded.
    $build = [int][Environment]::OSVersion.Version.Build
    if ($build -lt 18362) {
        Say "This needs Windows 10 version 1903 or newer (this is build $build)." 'Yellow'
        return
    }

    # WebView2 draws the app's windows. Windows 11 and current Windows 10 both
    # ship it; a machine without it gets Microsoft's own bootstrapper, which is
    # also what the bundled installer would fetch.
    function Test-WebView2 {
        $keys = @(
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
            'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
            'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        )
        foreach ($key in $keys) {
            if (Test-Path $key) {
                $pv = (Get-ItemProperty $key -Name pv -ErrorAction SilentlyContinue).pv
                if ($pv -and $pv -ne '0.0.0.0') { return $true }
            }
        }
        return $false
    }

    if (-not (Test-WebView2)) {
        Say '  installing the WebView2 runtime the app draws with...'
        $bootstrapper = Join-Path ([IO.Path]::GetTempPath()) 'MicrosoftEdgeWebview2Setup.exe'
        Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' `
            -OutFile $bootstrapper -UseBasicParsing
        Start-Process -FilePath $bootstrapper -ArgumentList '/silent', '/install' -Wait
        Remove-Item $bootstrapper -ErrorAction SilentlyContinue
    }

    # --- the app -------------------------------------------------------------
    $setup = $null
    $temp = $null

    if ($FromFile) {
        if (-not (Test-Path $FromFile)) { throw "No such file: $FromFile" }
        $setup = (Resolve-Path $FromFile).Path
        Say "  using $setup"
    } else {
        # The /releases/latest/download/ redirect needs no API call, so it
        # never hits GitHub's anonymous rate limit -- the same reason the Mac
        # installer stopped calling the API.
        $url = if ($Version) {
            "https://github.com/$Owner/$Repo/releases/download/$Version/R9-Capture-setup.exe"
        } else {
            "https://github.com/$Owner/$Repo/releases/latest/download/R9-Capture-setup.exe"
        }
        Say '  downloading the latest R9 Capture...'
        $temp = Join-Path ([IO.Path]::GetTempPath()) 'R9-Capture-setup.exe'
        Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
        $setup = $temp
    }

    # A running copy holds its own .exe open, so an upgrade has to close it
    # first. It lives in the tray, so there is usually one running.
    Get-Process 'R9Capture' -ErrorAction SilentlyContinue | ForEach-Object {
        $_.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 400
        if (-not $_.HasExited) { $_ | Stop-Process -Force -ErrorAction SilentlyContinue }
    }
    Start-Sleep -Milliseconds 600

    # /S is NSIS's silent switch. The bundle installs per-user, so this needs
    # no elevation and never shows a UAC prompt.
    Say '  installing...'
    $proc = Start-Process -FilePath $setup -ArgumentList '/S' -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "The installer exited with code $($proc.ExitCode)."
    }
    if ($temp) { Remove-Item $temp -ErrorAction SilentlyContinue }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "$AppName\R9Capture.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\$AppName\R9Capture.exe"),
        (Join-Path ${env:ProgramFiles} "$AppName\R9Capture.exe")
    )
    $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    Say ''
    if ($exe) {
        Say "Installed to $exe" 'Green'

        # Start with Windows, so the capture keys are simply there rather than
        # something to remember to launch. Per-user, so still no elevation.
        try {
            $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
            New-ItemProperty -Path $runKey -Name 'R9 Capture' -Value "`"$exe`"" `
                -PropertyType String -Force | Out-Null
            Say '  set to start with Windows'
        } catch {
            Say '  (could not set start-with-Windows)'
        }

        Start-Process -FilePath $exe
        Say ''
        Say 'R9 Capture is running. Look for its icon in the system tray.' 'Green'
    } else {
        Say 'Installed. Launch R9 Capture from the Start menu.' 'Green'
    }

    Say ''
    Say 'Click the tray icon for the panel: screenshots, recording, the focus'
    Say 'key, the radial annotate menu and the face-cam bubble. While a take is'
    Say 'running, one click on the same icon stops it.'
    Say ''
    Say 'Nothing here asks for a permission dialog -- but Windows will ask once'
    Say 'for the camera if you turn the face-cam bubble on.' 'DarkGray'
    Say ''
}

Invoke-R9CaptureInstall -Version $Version -FromFile $FromFile
