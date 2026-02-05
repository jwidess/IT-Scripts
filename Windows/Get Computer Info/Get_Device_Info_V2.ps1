# Get_Device_Info_V2.ps1
# ---------------------------------------------
# This script gathers system, hardware, network, and domain information
# from a Windows computer, saves the results to text and HTML files, and
# compresses them into a single .zip archive.
#
# Information collected includes:
#   - Group Policy results (gpresult)
#   - Hardware info (CPU, RAM, BIOS, Disks, GPU)
#   - Network configuration (ipconfig, route)
#   - Operating system details
#
# Usage:
#   - Run this script as a local administrator for best results.
#   - The output .zip file will be created in the same directory as the script.
#   - Temporary files are cleaned up after compression.
# ---------------------------------------------

Write-Host "----------------------------"
Write-Host "Running info gather..." -ForegroundColor Blue
Write-Host "----------------------------"

# Define output directory and files
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = "$scriptDir\SystemInfo"
$shortDate = (Get-Date -Format "MM-dd-yyyy")
$computerName = $env:COMPUTERNAME
$zipFile = $scriptDir + "\" + "SystemInfo_" + $computerName + "_" + $shortDate + ".zip"

# Ensure the output directory is empty and exists
if (Test-Path -Path $outputDir) {
    Remove-Item -Path $outputDir\* -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Gather domain and group policy information
$gpResultFile = "$outputDir\GPResult_$computerName.html"
gpresult /H $gpResultFile

# Gather hardware information
$hardwareInfoFile = "$outputDir\HardwareInfo_$computerName.txt"
Get-CimInstance CIM_ComputerSystem | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

#Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object {$_.Sum / 1GB} | Out-File -Append $hardwareInfoFile
# Calculate total RAM in GB and append "RAM: <value>GB"
$totalRAM = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object { [math]::Round($_.Sum / 1GB, 2) }
Add-Content -Path $hardwareInfoFile -Value "RAM: $totalRAM GB"

# Append RAM speed and model number
$ramModules = Get-CimInstance Win32_PhysicalMemory
foreach ($module in $ramModules) {
    # Append RAM details with speed and model number
    Add-Content -Path $hardwareInfoFile -Value "RAM Speed: $($module.Speed) MHz, Model: $($module.PartNumber)"
}

Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
Get-CimInstance CIM_BIOSElement | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
Get-CimInstance CIM_Processor | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

# Disk Info
Get-CimInstance Win32_LogicalDisk | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "--- Get-PhysicalDisk Info ---`r`n"
Get-PhysicalDisk | Select-Object DeviceID, MediaType, Model, SerialNumber, BusType | Format-Table -AutoSize | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "--- Get-CimInstance -ClassName Win32_DiskDrive Info ---`r`n"
Get-CimInstance -ClassName Win32_DiskDrive | Select-Object DeviceID, MediaType, Model, SerialNumber | Out-File -Append $hardwareInfoFile

Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
wmic cpu list /format:list | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
Get-CimInstance Win32_VideoController | Out-File -Append $hardwareInfoFile
Add-Content -Path $hardwareInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

# Gather network configuration
$networkInfoFile = "$outputDir\NetworkInfo_$computerName.txt"
ipconfig /all | Out-File -Append $networkInfoFile
Add-Content -Path $networkInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
route print | Out-File -Append $networkInfoFile
Add-Content -Path $networkInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

# Gather OS info
$osInfoFile = "$outputDir\OSInfo_$computerName.txt"
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Version, Caption | Out-File $osInfoFile
Add-Content -Path $osInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
Get-ComputerInfo | Out-File -Append $osInfoFile
Add-Content -Path $osInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

# Gather and append Windows License Information
Add-Content -Path $osInfoFile -Value "`r`n=== Windows License Information ===`r`n"
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Add-Content -Path $osInfoFile -Value "Computer Name: $($os.CSName)"
Add-Content -Path $osInfoFile -Value "OS Caption: $($os.Caption)"
Add-Content -Path $osInfoFile -Value "OS Version: $($os.Version)"
Add-Content -Path $osInfoFile -Value "OS Build Number: $($os.BuildNumber)"
Add-Content -Path $osInfoFile -Value ""

# Get Software Licensing info
$lic = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey }
if ($lic) {
    Add-Content -Path $osInfoFile -Value "Product Name: $($lic.Name)"
    Add-Content -Path $osInfoFile -Value "Description: $($lic.Description)"
    Add-Content -Path $osInfoFile -Value "License Status: $($lic.LicenseStatus)"
    Add-Content -Path $osInfoFile -Value "Partial Product Key: $($lic.PartialProductKey)"
    Add-Content -Path $osInfoFile -Value "Product Key Channel: $($lic.ProductKeyChannel)"
    Add-Content -Path $osInfoFile -Value "License Family: $($lic.LicenseFamily)"
    Add-Content -Path $osInfoFile -Value ""
} else {
    Add-Content -Path $osInfoFile -Value "No license information found."
}

# Get activation status
$slmgr = & cscript.exe //Nologo "$env:SystemRoot\System32\slmgr.vbs" /dli
Add-Content -Path $osInfoFile -Value "=== SLMGR /DLI Output ==="
Add-Content -Path $osInfoFile -Value $slmgr

$slmgr2 = & cscript.exe //Nologo "$env:SystemRoot\System32\slmgr.vbs" /xpr
Add-Content -Path $osInfoFile -Value "=== SLMGR /XPR Output ==="
Add-Content -Path $osInfoFile -Value $slmgr2

# Get Volume Activation info (if available)
$vol = Get-CimInstance -ClassName SoftwareLicensingService
if ($vol) {
    Add-Content -Path $osInfoFile -Value "Remaining Windows Rearm Count: $($vol.RemainingWindowsReArmCount)"
    Add-Content -Path $osInfoFile -Value "VL Activation Expiration: $($vol.VLActivationExpiration)"
    Add-Content -Path $osInfoFile -Value "VL Activation Interval: $($vol.VLActivationInterval)"
    Add-Content -Path $osInfoFile -Value "VL Renewal Interval: $($vol.VLRenewalInterval)"
    Add-Content -Path $osInfoFile -Value ""
}
Add-Content -Path $osInfoFile -Value "=== End of License Information ===`r`n"
# Compress the collected files into a .zip
if (Test-Path -Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}
Compress-Archive -Path $outputDir\* -DestinationPath $zipFile

# Remove the temp dir if compression is successful
if (Test-Path -Path $zipFile) {
    Remove-Item -Path $outputDir -Recurse -Force
    
    # Open file explorer with path of output zip
    Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$zipFile`""
}

Write-Host "----------------------------"
Write-Host "Information has been gathered and saved to: "
Write-Host "$zipFile" -ForegroundColor Green
Write-Host "----------------------------"
pause
