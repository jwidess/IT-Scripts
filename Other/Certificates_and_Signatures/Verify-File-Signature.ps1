<#
.SYNOPSIS
    Verifies an executable or DLL's signature and trust chain, alongside Zone Identifier.
.DESCRIPTION
    Runs, signtool.exe, Get-AuthenticodeSignature, and checks for Zone.Identifier alternate data stream.
#>

# --- Locate signtool ---
$SigntoolPath = "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe"

Write-Host "`n------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "EV / Authenticode Verification Script" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Using signtool path:" -ForegroundColor Yellow
Write-Host "  $SigntoolPath`n" -ForegroundColor White

if (-not (Test-Path $SigntoolPath)) {
    Write-Host "❌ signtool.exe not found at expected path." -ForegroundColor Red
    Write-Host "Please verify that the Windows SDK / Windows App Certification Kit is installed." -ForegroundColor Red
    exit 1
}


Read-Host "Press [Enter] to select a file to verify..."

# --- File picker dialog ---
Add-Type -AssemblyName System.Windows.Forms
$FileDialog = New-Object System.Windows.Forms.OpenFileDialog
$FileDialog.Title = "Select an exe or DLL to verify"
$FileDialog.Filter = "Executable and DLL files (*.exe;*.dll)|*.exe;*.dll|All files (*.*)|*.*"
$FileDialog.Multiselect = $false

if ($FileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting." -ForegroundColor Yellow
    exit
}

$FilePath = $FileDialog.FileName
Write-Host "`nSelected file:`n$FilePath`n" -ForegroundColor Cyan

# --- Run signtool verification ---
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Running signtool.exe verification..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------`n" -ForegroundColor DarkGray

& "$SigntoolPath" verify /pa /v /all "$FilePath"
$SigntoolExit = $LASTEXITCODE

if ($SigntoolExit -eq 0) {
    Write-Host "`n✅ signtool verification succeeded.`n" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ signtool reported issue(s) (exit code: $SigntoolExit).`n" -ForegroundColor Yellow
}

# --- Run PowerShell Authenticode verification ---
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Checking Authenticode signature with PowerShell..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------`n" -ForegroundColor DarkGray

$Signature = Get-AuthenticodeSignature -FilePath $FilePath

# Display all available properties
Write-Host "`nRaw AuthenticodeSignature output:`n" -ForegroundColor Yellow
$Signature | Format-List * 

# Highlight status
$StatusColor = if ($Signature.Status -eq 'Valid') { 'Green' } elseif ($Signature.Status -eq 'UnknownError') { 'Yellow' } else { 'Red' }
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Signature Status : $($Signature.Status)" -ForegroundColor $StatusColor
Write-Host "Signer           : $($Signature.SignerCertificate.Subject)"
Write-Host "Issuer           : $($Signature.SignerCertificate.Issuer)"
if ($Signature.TimeStamperCertificate) {
    Write-Host "Timestamped By   : $($Signature.TimeStamperCertificate.Subject)"
}
Write-Host "`nVerification complete.`n" -ForegroundColor Cyan

# --- Check Zone Identifier ---
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Checking Zone Identifier..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------`n" -ForegroundColor DarkGray

try {
    $ZoneStream = Get-Item -Path $FilePath -Stream Zone.Identifier -ErrorAction Stop
    
    Write-Host "✅ Zone Identifier stream found!" -ForegroundColor Yellow
    Write-Host "`nStream Details:" -ForegroundColor Cyan
    Write-Host "  Length: $($ZoneStream.Length) bytes" -ForegroundColor White
    
    # Read the Zone Identifier content
    $ZoneContent = Get-Content -Path $FilePath -Stream Zone.Identifier -ErrorAction Stop
    
    Write-Host "`nZone Identifier Content:" -ForegroundColor Cyan
    $ZoneContent | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    
    # Parse and explain ZoneId if present
    $ZoneIdLine = $ZoneContent | Where-Object { $_ -match '^ZoneId=(\d+)' }
    if ($ZoneIdLine -match 'ZoneId=(\d+)') {
        $ZoneId = $matches[1]
        $ZoneDescription = switch ($ZoneId) {
            "0" { "Local Machine (My Computer)" }
            "1" { "Local Intranet" }
            "2" { "Trusted Sites" }
            "3" { "Internet (Downloaded from web)" }
            "4" { "Restricted Sites" }
            default { "Unknown Zone" }
        }
        Write-Host "`n  Interpretation: Zone $ZoneId = $ZoneDescription" -ForegroundColor Yellow
        
        if ($ZoneId -eq "3") {
            Write-Host "  ⚠️  This file was downloaded from the Internet." -ForegroundColor Yellow
        }
    }
    
    # Check for HostUrl (download source)
    $HostUrlLine = $ZoneContent | Where-Object { $_ -match '^HostUrl=' }
    if ($HostUrlLine) {
        Write-Host "`n  File downloaded from:" -ForegroundColor Cyan
        Write-Host "  $($HostUrlLine -replace '^HostUrl=', '')" -ForegroundColor White
    }
    
    # Check for ReferrerUrl
    $ReferrerLine = $ZoneContent | Where-Object { $_ -match '^ReferrerUrl=' }
    if ($ReferrerLine) {
        Write-Host "`n  Referrer URL:" -ForegroundColor Cyan
        Write-Host "  $($ReferrerLine -replace '^ReferrerUrl=', '')" -ForegroundColor White
    }
}
catch {
    Write-Host "ℹ️  No Zone Identifier found." -ForegroundColor Green
}

Write-Host "`n------------------------------------------------------------`n" -ForegroundColor DarkGray

pause