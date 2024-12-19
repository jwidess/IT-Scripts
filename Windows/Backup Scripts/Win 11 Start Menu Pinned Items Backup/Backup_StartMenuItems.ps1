# Define the source folder for Start Menu files
$StartMenuPath = "$env:LocalAppData\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"

# Define the destination backup folder
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupFolder = Join-Path -Path $ScriptDirectory -ChildPath "StartMenuBackup"

# Create the backup folder if it doesn't exist
if (-not (Test-Path -Path $BackupFolder)) {
    New-Item -ItemType Directory -Path $BackupFolder | Out-Null
}

# Define the files to back up
$FilesToBackup = @("start.bin", "start2.bin")

# Copy each file to the backup folder
foreach ($File in $FilesToBackup) {
    $SourceFile = Join-Path -Path $StartMenuPath -ChildPath $File
    $DestinationFile = Join-Path -Path $BackupFolder -ChildPath $File

    if (Test-Path -Path $SourceFile) {
        Copy-Item -Path $SourceFile -Destination $DestinationFile -Force
        Write-Host "Backed up $File to $BackupFolder" -ForegroundColor Green
    } else {
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