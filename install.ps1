<#
.SYNOPSIS
    Installs R9 Capture on Windows.

.DESCRIPTION
    The Windows counterpart of the Mac's curl one-liner:

        irm https://raw.githubusercontent.com/XPro-Gamer-Rhine/R9-Capture-app/main/install.ps1 | iex

    R9 Capture is a single self-contained executable — a Win32 program that
    draws itself with Direct2D and talks to Windows' own capture, encoding and
    audio. There is no runtime to fetch, no framework to install, and nothing
    that needs administrator rights: it lands in your own profile, adds its
    shortcuts, and runs.

    Re-running upgrades in place. Settings live in %APPDATA%\R9 Capture and
    are never touched.

.PARAMETER Version
    Install a specific release tag instead of the latest.

.PARAMETER FromFile
    Install an executable already on disk, for testing a local build.

.PARAMETER Uninstall
    Remove it, including the shortcuts and the registry entries.
#>
[CmdletBinding()]
param(
    [string] $Version,
    [string] $FromFile,
    [switch] $Uninstall
)

# The whole install runs inside a function on purpose. This script is meant to
# be pasted as `irm ... | iex`, which executes in the caller's own session --
# so setting strict mode and $ErrorActionPreference at script level would leave
# the user's PowerShell window in that state long after the install finished.
function Invoke-R9CaptureInstall {
    param(
        [string] $Version,
        [string] $FromFile,
        [bool] $Uninstall
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $Owner   = 'XPro-Gamer-Rhine'
    $Repo    = 'R9-Capture-app'
    $AppName = 'R9 Capture'

    # Where to install.
    #
    # %LOCALAPPDATA% normally, but not when this script is being run from an
    # MSIX-packaged terminal. Those redirect every write under AppData into
    # their own container, so the app lands somewhere only that container can
    # see: the Start-menu entry comes up with a blank icon and the right-click
    # entry does nothing at all, because the path written into them does not
    # exist for Explorer. Nothing reports an error — the file is simply not
    # there. Outside AppData there is no redirection, so a packaged host gets
    # the profile root instead.
    # Asking the process whether it is packaged is not enough — a redirected
    # shell can still report no package identity. So make the folder and look
    # at where it actually went: a redirected one comes back with a Target
    # under Packages\<host>\LocalCache.
    function Test-Redirected([string] $Path) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
        try {
            $target = (Get-Item -LiteralPath $Path -Force).Target
            if ($target) {
                return [bool] (@($target) -match '\\Packages\\[^\\]+\\LocalCache\\')
            }
        } catch { }
        return $false
    }

    $Home_ = Join-Path $env:LOCALAPPDATA $AppName
    if (Test-Redirected $Home_) {
        $Home_ = Join-Path $env:USERPROFILE $AppName
    }
    $Exe     = Join-Path $Home_ 'R9Capture.exe'
    $RunKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $UninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"
    $StartMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $Shortcut  = Join-Path $StartMenu "$AppName.lnk"
    $Desktop   = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"

    function Say([string] $Text, [string] $Color = 'Cyan') {
        Write-Host $Text -ForegroundColor $Color
    }

    function Stop-Running {
        Get-Process 'R9Capture' -ErrorAction SilentlyContinue | ForEach-Object {
            $_.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 400
            if (-not $_.HasExited) { $_ | Stop-Process -Force -ErrorAction SilentlyContinue }
        }
        Start-Sleep -Milliseconds 500
    }

    if ($Uninstall) {
        Say ''
        Say "Removing $AppName"
        Stop-Running
        Remove-Item $Shortcut, $Desktop -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $RunKey -Name $AppName -ErrorAction SilentlyContinue
        Remove-Item $UninstallKey -Recurse -ErrorAction SilentlyContinue
        # Both candidate locations, so a copy left by an install that ran from
        # a packaged terminal goes too.
        foreach ($old in @($Home_, (Join-Path $env:LOCALAPPDATA $AppName), (Join-Path $env:USERPROFILE $AppName))) {
            Remove-Item $old -Recurse -Force -ErrorAction SilentlyContinue
        }
        foreach ($key in @(
            'HKCU:\Software\Classes\Directory\Background\shell\R9Capture',
            'HKCU:\Software\Classes\Directory\shell\R9Capture',
            'HKCU:\Software\Classes\DesktopBackground\shell\R9Capture',
            'HKCU:\Software\Classes\R9Capture.Menu')) {
            Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
        }
        Say 'Removed. Your settings in %APPDATA%\R9 Capture were left alone.' 'Green'
        Say ''
        return
    }

    Say ''
    Say "$AppName installer"
    Say ''

    # TLS 1.2 for Windows PowerShell 5.1, whose default is too old for GitHub.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Windows.Graphics.Capture, which is how every frame is taken, arrived in
    # Windows 10 1903. An older build would install fine and then be unable to
    # do the only thing the app is for, so it is told before anything is
    # downloaded.
    $build = [int][Environment]::OSVersion.Version.Build
    if ($build -lt 18362) {
        Say "This needs Windows 10 version 1903 or newer (this is build $build)." 'Yellow'
        return
    }

    New-Item -ItemType Directory -Force -Path $Home_ | Out-Null
    $target = Join-Path $Home_ 'R9Capture.exe'

    if ($FromFile) {
        if (-not (Test-Path $FromFile)) { throw "No such file: $FromFile" }
        Stop-Running
        Copy-Item (Resolve-Path $FromFile).Path $target -Force
        Say "  installed from $FromFile"
    } else {
        # The /releases/latest/download/ redirect needs no API call, so it
        # never hits GitHub's anonymous rate limit.
        $url = if ($Version) {
            "https://github.com/$Owner/$Repo/releases/download/$Version/R9Capture.exe"
        } else {
            "https://github.com/$Owner/$Repo/releases/latest/download/R9Capture.exe"
        }
        Say '  downloading the latest R9 Capture...'
        $temp = Join-Path ([IO.Path]::GetTempPath()) 'R9Capture.download.exe'
        Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
        Stop-Running
        Move-Item $temp $target -Force
    }

    # Shortcuts, so it has a name and a face in Search and on the Start menu.
    $shell = New-Object -ComObject WScript.Shell
    foreach ($path in @($Shortcut, $Desktop)) {
        $link = $shell.CreateShortcut($path)
        $link.TargetPath = $target
        $link.WorkingDirectory = $Home_
        $link.IconLocation = "$target,0"
        $link.Description = 'Screen capture and recording'
        $link.Save()
    }

    # An entry in Apps & features, with the icon, so it can be removed the
    # ordinary way rather than only by this script.
    New-Item -Path $UninstallKey -Force | Out-Null
    $version = (Get-Item $target).VersionInfo.ProductVersion
    if (-not $version) { $version = '1.9.1' }
    New-ItemProperty -Path $UninstallKey -Name 'DisplayName' -Value $AppName -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'DisplayIcon' -Value $target -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'DisplayVersion' -Value $version -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'Publisher' -Value 'Rhineul Islam' -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'InstallLocation' -Value $Home_ -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'NoModify' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'NoRepair' -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $UninstallKey -Name 'UninstallString' `
        -Value ('powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm ' +
                "https://raw.githubusercontent.com/$Owner/$Repo/main/install.ps1" +
                '))) -Uninstall"') `
        -Force | Out-Null

    # Start with Windows, so the capture keys are simply there.
    try {
        New-ItemProperty -Path $RunKey -Name $AppName -Value "`"$target`"" `
            -PropertyType String -Force | Out-Null
        Say '  set to start with Windows'
    } catch {
        Say '  (could not set start-with-Windows)'
    }

    Start-Process -FilePath $target
    Say ''
    Say "Installed to $target" 'Green'
    Say 'R9 Capture is running. Look for its icon in the system tray.' 'Green'
    Say ''
    Say 'Click the tray icon for the panel. While a take is running, one click'
    Say 'on the same icon stops it, and a floating bar gives you pause and stop.'
    Say ''
}

Invoke-R9CaptureInstall -Version $Version -FromFile $FromFile -Uninstall:$Uninstall.IsPresent
