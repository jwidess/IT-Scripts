# =============================================
# Find_Registry_Keys.ps1
# ---------------------------------------------
# This script prompts the user for a search term, then searches the Windows
# registry (HKLM and HKCU) for any registry key names containing that term.
# Results are exported to a CSV file in the script folder.
# ---------------------------------------------
# Author: Jwidess
# =============================================

# Prompt for search term
$searchTerm = Read-Host "Enter the registry search term"

# Define registry hives to search
$hives = @("HKLM", "HKCU")
$results = @()
$safeSearchTerm = $searchTerm -replace '[^a-zA-Z0-9_-]', '_'
$outputFile = Join-Path $PSScriptRoot "RegistrySearchResults_$safeSearchTerm.csv"

foreach ($hive in $hives) {
    Write-Host "Searching in $hive..." -ForegroundColor Cyan
    try {
        Get-ChildItem -Path "${hive}:\" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -like "*$searchTerm*") {
                $results += [PSCustomObject]@{
                    Hive    = $hive
                    KeyPath = $_.Name
                }
            }
        }
    } catch {
        Write-Host "Error searching ${hive}: $_" -ForegroundColor Red
    }
}

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    Write-Host "Results exported to $outputFile" -ForegroundColor Green
} else {
    Write-Host "No matching registry keys found." -ForegroundColor Yellow
}
pause