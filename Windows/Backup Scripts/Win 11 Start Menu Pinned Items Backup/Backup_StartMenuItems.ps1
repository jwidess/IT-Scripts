# Backup_StartMenuItems.ps1
# ---------------------------------------------
# This script backs up the pinned items (start.bin and start2.bin)
# from the Windows 11 Start Menu for the current user.
#
# The backup files are copied from:
#   %LocalAppData%\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState
# to a folder named 'StartMenuBackup' in the same directory as this script.
#
# To restore, copy the backed up files back to the original location.
# ---------------------------------------------

Write-Host "This script will back up your Windows 11 Start Menu pinned items." -ForegroundColor Cyan
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host

# Check if at least one of the files exists before proceeding
$StartMenuPath = "$env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
$FilesToBackup = @("start.bin", "start2.bin")
$AnyFileExists = $false
foreach ($File in $FilesToBackup) {
    $SourceFile = Join-Path -Path $StartMenuPath -ChildPath $File
    if (Test-Path -Path $SourceFile) {
        $AnyFileExists = $true
        break
    }
}
if (-not $AnyFileExists) {
    Write-Host "Neither start.bin nor start2.bin exists in $StartMenuPath. No backup will be performed." -ForegroundColor Red
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host
    exit
}

# Define the destination backup folder
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupFolder = Join-Path -Path $ScriptDirectory -ChildPath "StartMenuBackup"

# Create the backup folder if it doesn't exist
if (-not (Test-Path -Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder | Out-Null
}


# Copy each file to the backup folder
foreach ($File in $FilesToBackup) {
    $SourceFile = Join-Path -Path $StartMenuPath -ChildPath $File
    $DestinationFile = Join-Path -Path $BackupFolder -ChildPath $File

    if (Test-Path -Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
        Write-Host "Backed up $File to $BackupFolder" -ForegroundColor Green
    }
    else {
        Write-Host "$File does not exist in $StartMenuPath" -ForegroundColor Yellow
    }
}
Write-Host "----------------------------"
Write-Host "Backup process completed." -ForegroundColor Cyan
Write-Host "----------------------------"
Write-Host "To restore, place the `"start.bin`" or `"start2.bin`" file in:"
Write-Host "%LocalAppData%\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
Write-Host "----------------------------"
pause