# Firewall_UNBlock_All_EXE_in_Folder_Mk2.ps1
# ---------------------------------------------
# This script recursively finds all .exe files in the current directory and subdirectories,
# displays the list and total count, and prompts the user for confirmation before REMOVING
# Windows Firewall rules that block each .exe (both inbound and outbound).
#
# Inspired by: https://www.youtube.com/watch?v=4AH4SV7bGN0
# ---------------------------------------------

# Check for admin privs
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "This script must be run as Administrator!" -ForegroundColor Red
  Write-Host "Right-click the script and select 'Run with PowerShell (Admin)' or run from an elevated PowerShell window." -ForegroundColor Yellow
  pause
  exit
}

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Firewall_UNBlock_All_Folder_Mk2.ps1" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "This script will recursively UNBLOCK all .exe files in this folder and its subfolders by removing matching firewall rules." -ForegroundColor Yellow
Write-Host "PLACE THIS SCRIPT IN THE LOCATION TO UNBLOCK RECURSIVELY!" -ForegroundColor Yellow
Write-Host ("Current working directory: {0}" -f (Get-Location)) -ForegroundColor Red
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Read-Host "Press Enter to begin"

# Get all .exe files recursively from the current directory
$ExeFiles = Get-ChildItem -Path (Get-Location) -Recurse -Filter *.exe -File | Select-Object -ExpandProperty FullName

if (-not $ExeFiles) {
  Write-Host "No .exe files found in this directory or its subdirectories." -ForegroundColor Red
  pause
  exit
}

# Show the list and total
Write-Host "The following .exe files will be UNBLOCKED (firewall rules will be removed):" -ForegroundColor Green
$ExeFiles | ForEach-Object { Write-Host $_ }
Write-Host "------------------------------------------------------------"
Write-Host ("Total .exe files found: {0}" -f $ExeFiles.Count) -ForegroundColor Cyan

# First confirm
$confirmation = Read-Host "Do you want to proceed with UNBLOCKING these files in Windows Firewall? (Y/N)"
if ($confirmation -notin @('Y', 'y', 'Yes', 'yes')) {
  Write-Host "Operation cancelled by user." -ForegroundColor Yellow
  pause
  exit
}

# Remove firewall rules for each .exe
foreach ($exe in $ExeFiles) {
  $ruleName = "Blocked: $exe"
  netsh advfirewall firewall delete rule name="$ruleName" dir=in program="$exe"
  netsh advfirewall firewall delete rule name="$ruleName" dir=out program="$exe"
  Write-Host "Unblocked: $exe" -ForegroundColor Magenta
}

Write-Host "------------------------------------------------------------"
Write-Host "Unblocking complete. Press Enter to exit." -ForegroundColor Cyan
Read-Host
