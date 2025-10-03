# Remove_KB5063878.ps1
#https://www.windowscentral.com/microsoft/windows-11/reports-say-windows-11-update-is-bricking-drives-is-yours-on-the-list

# Check for Admin Privileges 
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "Script is not running as Administrator. Relaunching with elevated privileges..." -ForegroundColor Yellow

    # Relaunch PowerShell with "Run as Administrator"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"   # <-- this triggers the UAC prompt

    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Elevation was canceled. Exiting." -ForegroundColor Red
    }

    exit
}

$KB = "5063878"

Write-Host "Checking if KB$KB is installed..." -ForegroundColor Cyan

# Check if the update is installed
$update = Get-HotFix | Where-Object { $_.HotFixID -eq "KB$KB" }

if ($update) {
    Write-Host "KB$KB is installed." -ForegroundColor Yellow

    # KB5063878 can't be uninstalled if Windows Sandbox is enabled (error code 0x800F0825)
    $sandbox = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM"

    if ($sandbox.State -eq "Enabled") {
        Write-Host "Windows Sandbox is enabled. Please uninstall it before removing KB$KB." -ForegroundColor Red
    } else {
        Write-Host "Windows Sandbox is not installed. Proceeding with KB$KB uninstall..." -ForegroundColor Cyan

        $process = Start-Process -FilePath "wusa.exe" -ArgumentList "/uninstall /kb:$KB /norestart" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Host "KB$KB uninstallation completed successfully (restart may be required)." -ForegroundColor Green
        } else {
            Write-Host "KB$KB uninstallation failed with exit code $($process.ExitCode)." -ForegroundColor Red
        }
    }
} else {
    Write-Host "KB$KB is not installed on this system." -ForegroundColor Green
}

# --- Hide KB with COM API ---
Write-Host "Blocking KB$KB from reinstalling (COM API)..." -ForegroundColor Cyan
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$Updates = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'").Updates

$hidden = $false
foreach ($Update in $Updates) {
    if ($Update.Title -match "KB$KB") {
        $Update.IsHidden = $true
        Write-Host "KB$KB has been hidden from Windows Update (COM API)." -ForegroundColor Green
        $hidden = $true
    }
}
if (-not $hidden) {
    Write-Host "KB$KB not found in COM update search (may already be hidden or not yet offered)." -ForegroundColor Yellow
}

# --- Hide KB with PSWindowsUpdate ---
Write-Host "Attempting to block KB$KB using PSWindowsUpdate..." -ForegroundColor Cyan

# Ensure PSWindowsUpdate module is installed
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -ErrorAction Stop
        Write-Host "PSWindowsUpdate module installed." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install PSWindowsUpdate module: $_" -ForegroundColor Red
    }
}

Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue

try {
    Hide-WindowsUpdate -KBArticleID "KB$KB" -Hide -Confirm:$false -ErrorAction Stop
    Write-Host "KB$KB has been hidden from Windows Update (PSWindowsUpdate)." -ForegroundColor Green
} catch {
    Write-Host "PSWindowsUpdate could not hide KB$KB : $_" -ForegroundColor Yellow
}

pause
