# This script is used for copying a Windows installs "Users" folder
# without file permission structures to make migrating easier.
# It excludes AppData folders and the whatever exclusions are defined below

# Source Users folder to copy from
$source = "E:\Users"
# Destination folder for copying Users to
$destination = "H:\Users"
$excludeDirs = @()

# Add exclusion folders
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
$robocopyCommand = "robocopy $source $destination /E /COPY:DAT"

# Append the exclusion directories to the robocopy command
foreach ($dir in $excludeDirs) {
    $robocopyCommand += " /XD `"$dir`""
}

echo "Generated Command: "
echo $robocopyCommand

# Execute the command
#Invoke-Expression $robocopyCommand
pause
