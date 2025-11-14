# Get_License_Info.ps1
# ---------------------------------------------
# PowerShell script to retrieve Windows license information
# ---------------------------------------------

# Get OS info
Write-Host "=== Windows License Information ===" -ForegroundColor Cyan
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host "Computer Name: $($os.CSName)"
Write-Host "OS Caption: $($os.Caption)"
Write-Host "OS Version: $($os.Version)"
Write-Host "OS Build Number: $($os.BuildNumber)"
Write-Host ""

# Get Software Licensing info
$lic = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
if ($lic) {
    Write-Host "Product Name: $($lic.Name)"
    Write-Host "Description: $($lic.Description)"
    Write-Host "License Status: $($lic.LicenseStatus)"
    Write-Host "Partial Product Key: $($lic.PartialProductKey)"
    Write-Host "Product Key Channel: $($lic.ProductKeyChannel)"
    Write-Host "License Family: $($lic.LicenseFamily)"
    Write-Host ""
} else {
    Write-Host "No license information found." -ForegroundColor Yellow
}

# Get activation status
$slmgr = & cscript.exe //Nologo "$env:SystemRoot\System32\slmgr.vbs" /dli
Write-Host "=== SLMGR /DLI Output ==="
Write-Host $slmgr
Write-Host ""

$slmgr2 = & cscript.exe //Nologo "$env:SystemRoot\System32\slmgr.vbs" /xpr
Write-Host "=== SLMGR /XPR Output ==="
Write-Host $slmgr2
Write-Host ""

# Get Volume Activation info (if available)
$vol = Get-CimInstance -ClassName SoftwareLicensingService
if ($vol) {
    Write-Host "Remaining Windows Rearm Count: $($vol.RemainingWindowsReArmCount)"
    Write-Host "VL Activation Expiration: $($vol.VLActivationExpiration)"
    Write-Host "VL Activation Interval: $($vol.VLActivationInterval)"
    Write-Host "VL Renewal Interval: $($vol.VLRenewalInterval)"
    Write-Host ""
}

Write-Host "=== End of License Information ===" -ForegroundColor Cyan
pause