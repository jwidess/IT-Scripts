# BackupToDrive.ps1

# List of directories to back up
$SourceDirs = @(
    "M:\TestSource\FileToInclude"
)

# List of directories to exclude
$ExcludeDirs = @(
    "M:\TestSource\Exclude",
    "M:\TestSource\FileToInclude\Exclude Within"
)

# Destination backup location
$BackupLocation = "M:\Backup"

 # Path to error log CSV in backup location
$ErrorLogPath = Join-Path $BackupLocation "BackupErrors.csv"

# Track if any errors have occurred
$ErrorOccurred = $false

# Function to check if a path should be excluded
function Is-Excluded {
    param($Path)
    foreach ($Ex in $ExcludeDirs) {
        if ($Path -like "$Ex*") { return $true }
    }
    return $false
}

foreach ($SourceDir in $SourceDirs) {
    $BaseName = Split-Path $SourceDir -Leaf
    $DestDir = Join-Path $BackupLocation $BaseName

    # Get all items recursively, excluding specified directories
    $Items = Get-ChildItem -Path $SourceDir -Recurse -Force | Where-Object {
        -not (Is-Excluded $_.FullName)
    }

    foreach ($Item in $Items) {
        $RelativePath = $Item.FullName.Substring($SourceDir.Length)
        $TargetPath = Join-Path $DestDir $RelativePath

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
}

Write-Host "Backup complete."
pause