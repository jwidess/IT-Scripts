# List_Installed_Software_CSV.ps1
# ---------------------------------------------
# This script collects a list of installed software
# from both 32-bit and 64-bit registry locations, including user-specific
# installs. It outputs a CSV file with the following data:
# FriendlyName, Version, Publisher, PackageName, InstallDate, EstimatedSizeMB,
# URLInfoAbout, Comments.
# ---------------------------------------------


# Get the current script directory
$currentDir = Get-Location

# Get the computer name
$pcName = $env:COMPUTERNAME

# Get the current date in MM-dd-yyyy format
$currentDate = Get-Date -Format "MM-dd-yyyy"

# Define the output file path with PC name and date
$outputFile = Join-Path -Path $currentDir -ChildPath "InstalledSoftware_${pcName}_$currentDate.csv"

Write-Host "[INFO] Starting software inventory..." -ForegroundColor Cyan

# Registry paths for installed software (32 and 64 bit)
$regPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
)

$softwareList = @()
$totalFound = 0
foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        Write-Host "[SCAN] Checking $regPath..." -ForegroundColor Yellow
        $items = Get-ChildItem -Path $regPath
        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PSPath
            if ($app.DisplayName) {
                $installDateRaw = $app.InstallDate
                $installDateFormatted = $null
                if ($installDateRaw) {
                    if ($installDateRaw -match '^(\d{8})$') {
                        # Format yyyyMMdd to MM/dd/yyyy
                        $year = $installDateRaw.Substring(0, 4)
                        $month = $installDateRaw.Substring(4, 2)
                        $day = $installDateRaw.Substring(6, 2)
                        $installDateFormatted = "$month/$day/$year"
                    }
                    else {
                        # Try to parse and reformat other date strings
                        try {
                            $parsedDate = [datetime]::Parse($installDateRaw)
                            $installDateFormatted = $parsedDate.ToString('MM/dd/yyyy')
                        }
                        catch {
                            $installDateFormatted = $installDateRaw
                        }
                    }
                }
                $softwareList += [PSCustomObject]@{
                    FriendlyName    = $app.DisplayName
                    Version         = $app.DisplayVersion
                    Publisher       = $app.Publisher
                    PackageName     = $item.PSChildName
                    InstallDate     = $installDateFormatted
                    EstimatedSizeMB = if ($app.EstimatedSize) { [math]::Round($app.EstimatedSize / 1024, 2) } else { $null } # Convert KB to MB
                    URLInfoAbout    = $app.URLInfoAbout
                    Comments        = $app.Comments
                }
                $totalFound++
                Write-Host "[FOUND] $($app.DisplayName) ($($app.DisplayVersion))" -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "[WARN] Registry path not found: $regPath" -ForegroundColor Red
    }
}

Write-Host "[INFO] Total software entries found: $totalFound" -ForegroundColor Yellow

# Export to CSV
$softwareList | Sort-Object FriendlyName | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "[SUCCESS] Installed software has been exported to $outputFile" -ForegroundColor Cyan
pause