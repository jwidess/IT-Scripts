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
Write-Host "Starting info gather..." -ForegroundColor Blue
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
