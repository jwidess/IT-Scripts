# Define the log file
$logFile = "$env:Temp\RemoveXboxPackages.log"

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $Message"
}

# Start logging
Write-Log "Script started"

# Remove provisioned packages to prevent installation for new users
Write-Log "Attempting to remove provisioned packages"
try {
    $provisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*Microsoft.Xbox*"}
    foreach ($pkg in $provisionedPackages) {
        Write-Log "Removing provisioned package: $($pkg.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName
        Write-Log "Successfully removed provisioned package: $($pkg.DisplayName)"
    }
} catch {
    Write-Log "Error removing provisioned packages: $_"
}

# Attempt to remove installed packages for all users
Write-Log "Attempting to remove installed packages for all users"
try {
    $installedPackages = Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*Microsoft.Xbox*"}
    foreach ($pkg in $installedPackages) {
        Write-Log "Removing installed package: $($pkg.Name)"
        Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        Write-Log "Successfully removed installed package: $($pkg.Name)"
    }
} catch {
    Write-Log "Error removing installed packages: $_"
}

# End logging
Write-Log "Script completed"

