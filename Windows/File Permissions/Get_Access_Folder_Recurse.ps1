# PowerShell script to take ownership and reset permissions recursively
# Prompts for a folder path, then:
# - Takes ownership of all files and folders
# - Grants full control to the current user
# - Removes all other permissions

# Prompt for folder path
$folderPath = Read-Host "Enter the full path to the folder you want to unlock"

if (-not (Test-Path $folderPath)) {
    Write-Host "Path does not exist: $folderPath" -ForegroundColor Red
    exit 1
}

# Get current user
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "Taking ownership of all files and folders in $folderPath..."
# Take ownership recursively
icacls "$folderPath" /setowner "$currentUser" /T /C 

Write-Host "Granting full control to $currentUser..."
icacls "$folderPath" /grant "$($currentUser):(OI)(CI)F" /T /C 

Write-Host "Removing all other permissions..."
icacls "$folderPath" /reset /T /C 
icacls "$folderPath" /grant "$($currentUser):(OI)(CI)F" /T /C 

Write-Host "Done. $currentUser now has full control over $folderPath and all its contents." -ForegroundColor Green
pause