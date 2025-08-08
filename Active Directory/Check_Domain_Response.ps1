
# Display all network Connection-specific DNS Suffixes
$excludedSuffixes = @('lan', 'local', 'home', 'domain', 'corp', 'workgroup')
$dnsSuffixes = Get-DnsClient |
    Where-Object { $_.ConnectionSpecificSuffix -and $_.ConnectionSpecificSuffix -ne "" } |
    Select-Object -ExpandProperty ConnectionSpecificSuffix -Unique |
    Where-Object { $_ -notin $excludedSuffixes -and $_ -notmatch '^(lan|local|home|domain|corp|workgroup)$' }
if ($dnsSuffixes) {
    Write-Host "Found Connection-specific DNS Suffix(es):" -ForegroundColor Green
    foreach ($suffix in $dnsSuffixes) {
        Write-Host (" - $suffix") -ForegroundColor Cyan
    }
} else {
    Write-Host "No useful Connection-specific DNS Suffix found." -ForegroundColor Red
}

Write-Host "=========================================" -ForegroundColor Yellow
$DomainName = Read-Host -Prompt "Enter the domain name to check (e.g., ad.contoso.com)"

# Check if a domain name was provided
if ([string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Host "No domain name provided. Exiting..." -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

function Write-HorizontalLine {
    Write-Host "=========================================" -ForegroundColor Yellow
}

# nslookup for SRV records
Write-HorizontalLine
Write-Host "Running nslookup for SRV records..." -ForegroundColor Cyan
Write-HorizontalLine
nslookup -type=SRV _ldap._tcp.dc._msdcs.$DomainName

# nltest to get domain controller info
Write-HorizontalLine
Write-Host "Running nltest to get domain controller details..." -ForegroundColor Cyan
Write-HorizontalLine
nltest /dsgetdc:$DomainName

Write-HorizontalLine
Write-Host "Domain check completed." -ForegroundColor Green
Write-HorizontalLine
pause
