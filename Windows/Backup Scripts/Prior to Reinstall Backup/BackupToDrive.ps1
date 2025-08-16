# =============================================
# BackupToDrive.ps1
# ---------------------------------------------
# This script recursively backs up a set of directories to a specified location,
# excluding paths based on directory list, search terms, and system file rules.
# It removes NTFS permissions from copied files, and logs errors to CSV file.
# ---------------------------------------------
# Author: Jwidess
# =============================================


#!=============================================
#! Modify the following parameters as needed!
#!=============================================
# List of directories to back up
$SourceDirs = @(
    "M:\TestSource\FileToInclude"
)

# List of directories to exclude
$ExcludeDirs = @(
    "M:\TestSource\Exclude",
    "M:\TestSource\FileToInclude\Exclude Within"
)

# List of case-insensitive search terms to exclude
$ExcludeTerms = @(
    "OneDrive"
)

# Destination backup location
$BackupLocation = "M:\Backup"

# Path to error log CSV in backup location
$ErrorLogPath = Join-Path $BackupLocation "BackupErrors.csv"
#!=============================================

# Track if any errors have occurred
$ErrorOccurred = $false

# Function to check if a path should be excluded
function Is-Excluded {
    param($Path)
    # Exclude if path contains BOTH 'microsoft' and 'windows' (case-insensitive)
    # This is to prevent backing up system-related files
    if ($Path -match '(?i)microsoft' -and $Path -match '(?i)windows') {
        return $true
    }
    # Exclude if path contains any term in $ExcludeTerms (case-insensitive)
    foreach ($term in $ExcludeTerms) {
        if ($Path -match ("(?i)" + [Regex]::Escape($term))) {
            return $true
        }
    }
    foreach ($Ex in $ExcludeDirs) {
        if ($Path -like "$Ex*") { return $true }
    }
    return $false
}

# Custom recursive function to enumerate items with periodic count
function Get-AllItems {
    param(
        [string]$Path,
        [ref]$CountRef,
        [int]$Interval = 10000
    )
    $results = @()
    try {
        $children = Get-ChildItem -Path $Path -Force
        foreach ($child in $children) {
            if (-not (Is-Excluded $child.FullName)) {
                $results += $child
                $CountRef.Value++
                if ($CountRef.Value % $Interval -eq 0) {
                    Write-Host "Scanned $($CountRef.Value) items so far in $Path..."
                }
                if ($child.PSIsContainer) {
                    $results += Get-AllItems -Path $child.FullName -CountRef $CountRef -Interval $Interval
                }
            }
        }
    }
    catch {
        Write-Warning ("[SCAN ERROR] Access denied or error at: {0} | Reason: {1}" -f $Path, $_.Exception.Message)
    }
    return $results
}

foreach ($SourceDir in $SourceDirs) {
    $BaseName = Split-Path $SourceDir -Leaf
    $DestDir = Join-Path $BackupLocation $BaseName

    Write-Host "Scanning $SourceDir for files to back up..."
    $ScanCount = 0
    $Items = Get-AllItems -Path $SourceDir -CountRef ([ref]$ScanCount) -Interval 10000
    Write-Host "Found $($Items.Count) items to back up from $SourceDir. Starting backup..."

    $TotalItems = $Items.Count
    $Processed = 0
    $SummaryInterval = 1000

    foreach ($Item in $Items) {
        $Processed++
        $RelativePath = $Item.FullName.Substring($SourceDir.Length)
        $TargetPath = Join-Path $DestDir $RelativePath

        Write-Progress -Activity "Backing up files from $SourceDir" -Status "Processing $Processed of $TotalItems" -PercentComplete (($Processed / $TotalItems) * 100)

        if ($Processed % $SummaryInterval -eq 0) {
            Write-Host "Backed up $Processed of $TotalItems files from $SourceDir..."
        }

        try {
            if ($Item.PSIsContainer) {
                if (-not (Test-Path $TargetPath)) {
                    New-Item -ItemType Directory -Path $TargetPath | Out-Null
                }
            }
            else {
                $TargetDir = Split-Path $TargetPath
                if (-not (Test-Path $TargetDir)) {
                    New-Item -ItemType Directory -Path $TargetDir | Out-Null
                }
                Copy-Item $Item.FullName -Destination $TargetPath -Force
            }

            # Remove permissions and set to inherit from parent
            try {
                $acl = Get-Acl $TargetPath
                $acl.SetAccessRuleProtection($false, $true)
                Set-Acl -Path $TargetPath -AclObject $acl
            }
            catch {
                Write-Warning ("Failed to set permissions on {0}: {1}" -f $TargetPath, $_.Exception.Message)
                $ErrorMsg = $_.Exception.Message.Replace('"', '""')
                if (-not $ErrorOccurred) {
                    "FilePath,ErrorMessage" | Out-File -FilePath $ErrorLogPath -Encoding UTF8
                    $ErrorOccurred = $true
                }
                "$TargetPath,""$ErrorMsg""" | Out-File -FilePath $ErrorLogPath -Append -Encoding UTF8
            }
        }
        catch {
            Write-Warning ("General error on {0}: {1}" -f $TargetPath, $_.Exception.Message)
            $ErrorMsg = $_.Exception.Message.Replace('"', '""')
            if (-not $ErrorOccurred) {
                "FilePath,ErrorMessage" | Out-File -FilePath $ErrorLogPath -Encoding UTF8
                $ErrorOccurred = $true
            }
            "$TargetPath,""$ErrorMsg""" | Out-File -FilePath $ErrorLogPath -Append -Encoding UTF8
        }
    }
    # Print summary if less than $SummaryInterval files processed
    if ($Processed -lt $SummaryInterval) {
        Write-Host "Backed up $Processed of $TotalItems files from $SourceDir..."
    }
    Write-Progress -Activity "Backing up files from $SourceDir" -Completed
}

Write-Host "Backup complete." -ForegroundColor Green
pause