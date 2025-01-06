# Import Active Directory module if not already loaded
Import-Module ActiveDirectory

# Function to extract OU from DistinguishedName
function Get-OU {
    param ([string]$DistinguishedName)
    # Remove the "CN=" and return only the OU part
    return ($DistinguishedName -replace "^CN=.*?,", "")
}

# Enabled Users
$enabledUsers = Get-ADUser -Filter {Enabled -eq $true} -Properties Enabled, DistinguishedName
Write-Host "=== Enabled Users === (Count = $($enabledUsers.Count))" -ForegroundColor Green
$enabledUsers | Select-Object Name, SamAccountName, Enabled, @{Name='OU'; Expression={Get-OU $_.DistinguishedName}} | Format-Table -AutoSize

# Disabled Users
$disabledUsers = Get-ADUser -Filter {Enabled -eq $false} -Properties Enabled, DistinguishedName
Write-Host "`n=== Disabled Users === (Count = $($disabledUsers.Count))" -ForegroundColor Red
$disabledUsers | Select-Object Name, SamAccountName, Enabled, @{Name='OU'; Expression={Get-OU $_.DistinguishedName}} | Format-Table -AutoSize

# Enabled Computers
$enabledComputers = Get-ADComputer -Filter {Enabled -eq $true} -Properties Enabled, DistinguishedName
Write-Host "`n=== Enabled Computers === (Count = $($enabledComputers.Count))" -ForegroundColor Green
$enabledComputers | Select-Object Name, DNSHostName, Enabled, @{Name='OU'; Expression={Get-OU $_.DistinguishedName}} | Format-Table -AutoSize

# Disabled Computers
$disabledComputers = Get-ADComputer -Filter {Enabled -eq $false} -Properties Enabled, DistinguishedName
Write-Host "`n=== Disabled Computers === (Count = $($disabledComputers.Count))" -ForegroundColor Red
$disabledComputers | Select-Object Name, DNSHostName, Enabled, @{Name='OU'; Expression={Get-OU $_.DistinguishedName}} | Format-Table -AutoSize

pause