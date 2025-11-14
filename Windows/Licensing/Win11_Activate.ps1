# Win11_Activate.ps1
# ---------------------------------------------
# PowerShell script to activate Windows 11
# - Shows system info
# - Shows current license/activation status
# - Prompts for product key
# - Applies key and activates Windows
# ---------------------------------------------

# Check if running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting with elevated permissions..." -ForegroundColor Yellow
    
    # Restart the script with admin privileges
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "=== Windows 11 Activation Utility ===" -ForegroundColor Cyan
Write-Host ""

# Show basic system info
Write-Host "Gathering system information..." -ForegroundColor Yellow
$sys = Get-ComputerInfo
Write-Host "Computer Name: $($sys.CsName)"
Write-Host "OS Name:       $($sys.OsName)"
Write-Host "OS Version:    $($sys.OsVersion)"
Write-Host "Build Number:  $($sys.OsBuildNumber)"
Write-Host ""

# Show activation / license status
Write-Host "Retrieving current activation status..." -ForegroundColor Yellow

# Use slmgr to display licensing info
Write-Host ""
Write-Host "Current License Information:" -ForegroundColor Cyan
cscript /nologo "$env:SystemRoot\System32\slmgr.vbs" /dlv
Write-Host ""

# Prompt for product key
Write-Host ""
$productKey = Read-Host -Prompt "Enter your 25-character Windows product key (format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)"

if ($productKey -notmatch '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$') {
    Write-Host "ERROR: Invalid product key format." -ForegroundColor Red
    exit 1
}

Write-Host "Installing product key..." -ForegroundColor Yellow
cscript /nologo "$env:SystemRoot\System32\slmgr.vbs" /ipk $productKey

# Activate Windows
Write-Host "Activating Windows..." -ForegroundColor Yellow
cscript /nologo "$env:SystemRoot\System32\slmgr.vbs" /ato

Write-Host ""
Write-Host "Activation attempt complete." -ForegroundColor Green
Write-Host ""

# Display updated activation info
Write-Host "Updated License Information:" -ForegroundColor Cyan
cscript /nologo "$env:SystemRoot\System32\slmgr.vbs" /dli

pause
