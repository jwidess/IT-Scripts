# Prompt the user for the domain name
$DomainName = Read-Host -Prompt "Enter the domain name to check"

# Check if a domain name was provided
if ([string]::IsNullOrWhiteSpace($DomainName)) {
    Write-Host "No domain name provided. Exiting..." -ForegroundColor Red
    exit
}

# Function to print a horizontal line
function Write-HorizontalLine {
    Write-Host "=========================================" -ForegroundColor Yellow
}

# Perform nslookup for SRV records
Write-HorizontalLine
Write-Host "Running nslookup for SRV records..." -ForegroundColor Cyan
Write-HorizontalLine
nslookup -type=SRV _ldap._tcp.dc._msdcs.$DomainName

# Perform nltest to get domain controller info
Write-HorizontalLine
Write-Host "Running nltest to get domain controller details..." -ForegroundColor Cyan
Write-HorizontalLine
nltest /dsgetdc:$DomainName

# Completion message
Write-HorizontalLine
Write-Host "Domain check completed." -ForegroundColor Green
Write-HorizontalLine
pause
