# =============================================
# Find_Registry_Keys.ps1
# ---------------------------------------------
# This script prompts for a search term, then searches the Windows
# registry (HKLM and HKCU) for any registry key names containing that term.
# Results are exported to a CSV file in the script folder.
# ---------------------------------------------
# Author: Jwidess
# =============================================

# Prompt for search term
Write-Host "Enter the registry search term: " -NoNewline -ForegroundColor Yellow
$searchTerm = Read-Host

# Define registry hives to search
$hives = @("HKLM", "HKCU") # Default common hives
$results = @()
$safeSearchTerm = $searchTerm -replace '[^a-zA-Z0-9_-]', '_'

# Track start time
$startTime = Get-Date
$baseFileName = "RegistrySearchResults_$safeSearchTerm.csv"
$outputFile = Join-Path $PSScriptRoot $baseFileName
$fileIndex = 1
while (Test-Path $outputFile) {
    $outputFile = Join-Path $PSScriptRoot ("RegistrySearchResults_{0}_{1}.csv" -f $safeSearchTerm, $fileIndex)
    $fileIndex++
}

foreach ($hive in $hives) {
    Write-Host "Searching in $hive..." -ForegroundColor Cyan
    $spinner = @('|','/','-','\')
    $spinIndex = 0
    $searching = $true
    $hiveStartTime = Get-Date
    $job = Start-Job -ScriptBlock {
        param($hive, $searchTerm)
        Get-ChildItem -Path "${hive}:\" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$searchTerm*" }
    } -ArgumentList $hive, $searchTerm

    while ($searching) {
        Write-Host -NoNewline ("`r" + $spinner[$spinIndex] + " Searching...") -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 150
        $spinIndex = ($spinIndex + 1) % $spinner.Count
        if ((Get-Job -Id $job.Id).State -ne 'Running') {
            $searching = $false
        }
    }
    $hiveEndTime = Get-Date
    $hiveDuration = ($hiveEndTime - $hiveStartTime).TotalSeconds
    Write-Host ("`rDone searching $hive. (" + [math]::Round($hiveDuration,2) + " seconds)") -ForegroundColor Cyan
    $output = Receive-Job -Id $job.Id
    Remove-Job -Id $job.Id
    foreach ($item in $output) {
        $results += [PSCustomObject]@{
            Hive    = $hive
            KeyPath = $item.Name
        }
    }
}

if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    $uniqueResults = $results | Sort-Object KeyPath -Unique
    $uniqueCount = $uniqueResults.Count
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    Write-Host "Results exported to: $outputFile" -ForegroundColor Green
    Write-Host ("Unique entries found: " + $uniqueCount) -ForegroundColor Magenta
    Write-Host ("Total search time: " + [math]::Round($duration,2) + " seconds") -ForegroundColor Blue
} else {
    Write-Host "No matching registry keys found." -ForegroundColor Yellow
}
pause