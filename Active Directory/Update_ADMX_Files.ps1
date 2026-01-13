# Update_ADMX_Files.ps1
# ---------------------------------------------
# This script takes an input of new ADMX files
# and updates the central store on a DC. Only 
# updates en-US language files currently.
# ---------------------------------------------

# Check for admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrative privileges."
    Write-Warning "Script location: $($MyInvocation.MyCommand.Path)"
    Write-Error "Please run PowerShell as Administrator and try again."
    pause
    exit
}

# Welcome Screen
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "              ADMX Central Store Updater" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Find the latest Administrative Templates here:"
Write-Host "https://www.microsoft.com/en-us/search/explore?q=Administrative+Templates" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for the folder containing the new ADMX files
$sourcePath = Read-Host -Prompt "Enter the path to the extracted ADMX files"
Write-Host "Path: $sourcePath"


# Verify path exists
if (-not (Test-Path -Path $sourcePath)) {
    Write-Error "Source path '$sourcePath' does not exist."
    exit
}

# Prompt for the Central Store location
$destinationPath = Read-Host -Prompt "Enter the Central Store location (e.g. \\domain.com\SYSVOL\domain.com\Policies\PolicyDefinitions)"
Write-Host "Path: $destinationPath"

# Enforce pattern: \\domain\SYSVOL\domain\Policies\PolicyDefinitions (domains must match)
$centralStorePattern = '^\\\\(?<domain>[^\\]+)\\SYSVOL\\\k<domain>\\Policies\\PolicyDefinitions\\?$'
if ($destinationPath -notmatch $centralStorePattern) {
    Write-Warning "The provided path does not match the expected Central Store UNC format: \\domain.com\SYSVOL\domain.com\Policies\PolicyDefinitions"
    Write-Host "Provided: $destinationPath" -ForegroundColor Yellow
    $confirmPath = Read-Host "Are you sure you want to use this path? (Y/N)"
    if ($confirmPath -ne "Y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Red
        exit
    }
}

# Verify destination path exists
if (-not (Test-Path -Path $destinationPath)) {
    Write-Error "Destination path '$destinationPath' does not exist."
    exit
}

# Analysis Phase
Write-Host "`nAnalyzing changes..." -ForegroundColor Cyan

$updates = @()
$sourceEnUS = Join-Path -Path $sourcePath -ChildPath "en-US"
$destEnUS = Join-Path -Path $destinationPath -ChildPath "en-US"

# Analyze .admx files
Get-ChildItem -Path $sourcePath -Filter "*.admx" | ForEach-Object {
    $targetPath = Join-Path -Path $destinationPath -ChildPath $_.Name
    if (Test-Path -Path $targetPath) {
        $updates += [PSCustomObject]@{ Name = $_.Name; Status = "Overwrite" }
    } else {
        $updates += [PSCustomObject]@{ Name = $_.Name; Status = "New" }
    }
}

# Analyze en-US .adml files
if (Test-Path -Path $sourceEnUS) {
    Get-ChildItem -Path $sourceEnUS -Filter "*.adml" | ForEach-Object {
        $targetPath = Join-Path -Path $destEnUS -ChildPath $_.Name
        if (Test-Path -Path $targetPath) {
            $updates += [PSCustomObject]@{ Name = "en-US\$($_.Name)"; Status = "Overwrite" }
        } else {
            $updates += [PSCustomObject]@{ Name = "en-US\$($_.Name)"; Status = "New" }
        }
    }
}

# Report Findings
$overwrites = $updates | Where-Object { $_.Status -eq "Overwrite" }
$newFiles = $updates | Where-Object { $_.Status -eq "New" }

Write-Host "`nFiles to be OVERWRITTEN ($($overwrites.Count)):" -ForegroundColor Yellow
if ($overwrites.Count -gt 0) {
    $overwrites | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Yellow }
} else {
    Write-Host "  (None)" -ForegroundColor Gray
}

Write-Host "`nNew files to be ADDED ($($newFiles.Count)):" -ForegroundColor Green
if ($newFiles.Count -gt 0) {
    $newFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Green }
} else {
    Write-Host "  (None)" -ForegroundColor Gray
}

# Confirmation
$confirm = Read-Host "`nDo you want to proceed with these changes? (Y/N)"
if ($confirm -ne "Y") {
    Write-Host "Operation cancelled by user." -ForegroundColor Red
    exit
}

# Execution Phase

# Backup (store backup in the users Documents folder)
$destinationPath = $destinationPath.TrimEnd('\')
$backupTimestamp = Get-Date -Format 'yyyyMMdd-HHmm'
$documents = [Environment]::GetFolderPath('MyDocuments')
# Backup folder name in Documents: PolicyDefinitions_<timestamp>
$backupPath = Join-Path -Path $documents -ChildPath "PolicyDefinitions_${backupTimestamp}"
$backupCreated = $false

Write-Host "`nBacking up current PolicyDefinitions to '$backupPath'..." -ForegroundColor Cyan
try {
    Copy-Item -Path $destinationPath -Destination $backupPath -Recurse -Force -ErrorAction Stop
    Write-Host "Backup created at: $backupPath" -ForegroundColor Green
    $backupCreated = $true
}
catch {
    Write-Error "Failed to create backup. Error: $_"
    exit
}

Write-Host "`nCopying files..." -ForegroundColor Cyan

# Copy .admx files from root of source to destination
Get-ChildItem -Path $sourcePath -Filter "*.admx" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $destinationPath -Force
    $destFile = Join-Path -Path $destinationPath -ChildPath $_.Name
    (Get-Item $destFile).LastWriteTime = Get-Date
    Write-Host "Copied: $($_.Name)"
}

# Process en-US folder
if (Test-Path -Path $sourceEnUS) {
    # Create destination en-US directory if it doesn't exist
    if (-not (Test-Path -Path $destEnUS)) {
        New-Item -Path $destEnUS -ItemType Directory | Out-Null
    }

    Get-ChildItem -Path $sourceEnUS -Filter "*.adml" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $destEnUS -Force
        $destFile = Join-Path -Path $destEnUS -ChildPath $_.Name
        (Get-Item $destFile).LastWriteTime = Get-Date
        Write-Host "Copied: en-US\$($_.Name)"
    }
}
else {
    Write-Warning "The 'en-US' directory was not found in the source location."
}

Write-Host "Operation complete." -ForegroundColor Green

# Ask if user wants to delete the backup
if ($backupCreated) {
    $deleteBackup = Read-Host "`nDo you want to delete the backup at '$backupPath'? (Y/N)"
    if ($deleteBackup -eq 'Y') {
        try {
            Remove-Item -Path $backupPath -Recurse -Force -ErrorAction Stop
            Write-Host "Backup deleted: $backupPath" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to delete backup: $_"
        }
    }
    else {
        Write-Host "Backup retained at: $backupPath" -ForegroundColor Cyan
    }
}

pause