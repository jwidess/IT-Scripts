# Get the current script directory
$currentDir = Get-Location

# Get the current date in MM-dd-yyyy format
$currentDate = Get-Date -Format "MM-dd-yyyy"

# Define the output file path with date appended
$outputFile = Join-Path -Path $currentDir -ChildPath "InstalledSoftware_$currentDate.csv"

# Get the list of installed software
$installedSoftware = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor

# Export to CSV
$installedSoftware | Export-Csv -Path $outputFile -NoTypeInformation

# Notify user
Write-Host "Installed software has been exported to $outputFile"
pause