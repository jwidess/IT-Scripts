# This PS1 Script takes a list of CVEs and queries NIST CVE API for info
# Returns info inline and in a .csv file 
# Script was generated with ChatGPT

$CVEString = "CVE-2022-31813|CVE-2017-3167|CVE-2017-7679"  # Input string with pipe-separated CVEs
$CVEList = $CVEString -split "\|"  # Split the string into an array
$TotalCVEs = $CVEList.Count

$APIKey = "CHANGE_ME!"  #! Replace with your actual API key !

$Headers = @{ "apiKey" = $APIKey }  # Set up headers for authentication

$Results = @()

Write-Host "This script will gather CVE Info from nist.gov using the supplied API key." -ForegroundColor Cyan
# Create a custom object for each CVE
$CVEList | ForEach-Object {
    [PSCustomObject]@{ CVE = $_ }
} | Format-Table -AutoSize

Write-Host "Processing $TotalCVEs CVEs..." -ForegroundColor Cyan
pause
$Counter = 0  # Track progress

foreach ($CVE in $CVEList) {
    $Counter++
    Write-Host "[$Counter/$TotalCVEs] Fetching data for $CVE..." -ForegroundColor Yellow
    $URL = "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=$CVE"

    try {
        $Response = Invoke-RestMethod -Uri $URL -Method Get -Headers $Headers -ErrorAction Stop

        if ($Response.vulnerabilities) {
            $CVEData = $Response.vulnerabilities[0].cve
            $Description = $CVEData.descriptions | Where-Object { $_.lang -eq "en" } | Select-Object -ExpandProperty value
            $Severity = "Not Available"
            $CVSSScore = "N/A"

            # Extract severity (CVSS v3.1 preferred, fallback to v2 if missing)
            if ($CVEData.metrics.cvssMetricV31) {
                $Severity = $CVEData.metrics.cvssMetricV31[0].cvssData.baseSeverity
                $CVSSScore = $CVEData.metrics.cvssMetricV31[0].cvssData.baseScore
            } elseif ($CVEData.metrics.cvssMetricV2) {
                $Severity = $CVEData.metrics.cvssMetricV2[0].baseSeverity
                $CVSSScore = $CVEData.metrics.cvssMetricV2[0].cvssData.baseScore
            }

            $Results += [PSCustomObject]@{
                CVE         = $CVE
                Severity    = $Severity
                CVSSScore   = $CVSSScore
                Description = $Description
            }

            Write-Host "    -> Severity: $Severity (CVSS Score: $CVSSScore)" -ForegroundColor Green
        } else {
            $Results += [PSCustomObject]@{
                CVE         = $CVE
                Severity    = "Not Found"
                CVSSScore   = "N/A"
                Description = "No data available"
            }

            Write-Host "    -> No data found for $CVE" -ForegroundColor Red
        }
    } catch {
        Write-Host "    -> Error retrieving $CVE - $($_.Exception.Message)" -ForegroundColor Red
        $Results += [PSCustomObject]@{
            CVE         = $CVE
            Severity    = "Error"
            CVSSScore   = "N/A"
            Description = "API request failed"
        }
    }

    Start-Sleep -Milliseconds 1000  # Delay to avoid rate-limiting
}

# Export to CSV
$Results | Export-Csv -Path "CVE_Report.csv" -NoTypeInformation -Encoding UTF8

# Display results in a table
$Results | Format-Table -AutoSize

Write-Host "`nCVE report saved as 'CVE_Report.csv'" -ForegroundColor Cyan
