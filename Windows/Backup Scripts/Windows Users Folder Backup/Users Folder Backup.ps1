# This script is used for copying a Windows installs "Users" folder
# without file permission structures to make migrating easier.
# It excludes AppData folders and the whatever exclusions are defined below

# Source Users folder to copy from (change as needed)
$source = "E:\Users"
# Destination folder for copying Users to (change as needed)
$destination = "H:\Users"
$excludeDirs = @()

# Check if source directory exists
if (!(Test-Path -Path $source)) {
    Write-Host "Source directory $source does not exist. Exiting script." -ForegroundColor Red
    pause
    exit
}

# Add exclusion folders (change as needed)
$excludeDirs += "E:\Users\Default"
$excludeDirs += "E:\Users\Default User"
$excludeDirs += "E:\Users\All Users"

# Get all user directories in E:\Users
$userDirs = Get-ChildItem -Path $source -Directory

# Loop through each user directory and add its AppData directory to exclusions
foreach ($userDir in $userDirs) {
    $appDataPath = Join-Path -Path $userDir.FullName -ChildPath "AppData"
    if (Test-Path $appDataPath) {
        $excludeDirs += $appDataPath
    }
}

# Build the robocopy command with exclusions
$robocopyCommand = "robocopy `"$source`" `"$destination`" /E /COPY:DAT"

# Append the exclusion directories to the robocopy command
foreach ($dir in $excludeDirs) {
    $robocopyCommand += " /XD `"$dir`""
}


# Print summary
Write-Host ("Found {0} user folders in source." -f $userDirs.Count) -ForegroundColor Cyan
Write-Host ("Total exclusions: {0}" -f $excludeDirs.Count) -ForegroundColor Yellow
Write-Host "Generated Command:" -ForegroundColor Green
Write-Host $robocopyCommand -ForegroundColor White

# Prompt to continue before executing the command
Read-Host "Press Enter to execute the above command, or Ctrl+C to cancel"

# Execute the command
Invoke-Expression $robocopyCommand
pause
