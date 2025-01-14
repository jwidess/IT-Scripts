# Define the log file
$logFile = "$env:Temp\RemoveXbox_Logon.log"

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $Message"
}

# Start logging
Write-Log "Logon script started for user: $env:USERNAME"

# Attempt to remove Xbox-related packages
try {
    $packages = Get-AppxPackage *Microsoft.Xbox*
    foreach ($pkg in $packages) {
        Write-Log "Removing package: $($pkg.Name)"
        Remove-AppxPackage -Package $pkg.PackageFullName
        Write-Log "Successfully removed package: $($pkg.Name)"
    }
} catch {
    Write-Log "Error removing Appx packages: $_"
}

# End logging
Write-Log "Logon script completed"

