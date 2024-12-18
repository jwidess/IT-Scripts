# Script to gather system and domain information, and compress it into a .zip file
Write-Host "----------------------------"
Write-Host "Starting info gather..." -ForegroundColor Blue
Write-Host "----------------------------"

# Define output directory and files
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = "$scriptDir\SystemInfo"
$shortDate = (Get-Date -Format "MM-dd-yyyy")
$computerName = $env:COMPUTERNAME
$zipFile = $scriptDir + "\" + "SystemInfo_" + $computerName + "_" + $shortDate + ".zip"
#$zipFile = "$scriptDir\SystemInfo_$computerName_$shortDate.zip"

# Check if the output directory exists and clean it up if necessary
if (Test-Path -Path $outputDir) {
    $files = Get-ChildItem -Path $outputDir
    if ($files) {
        Remove-Item -Path $outputDir\* -Recurse -Force
    }
}

# Ensure the output directory exists
if (!(Test-Path -Path $outputDir)) {
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
Get-CimInstance Win32_LogicalDisk | Out-File -Append $hardwareInfoFile
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

# Gather operating system information
$osInfoFile = "$outputDir\OSInfo_$computerName.txt"
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Version, Caption | Out-File $osInfoFile
Add-Content -Path $osInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"
Get-ComputerInfo | Out-File -Append $osInfoFile
Add-Content -Path $osInfoFile -Value "---------------------------------------------------------------------------------------------------`r`n"

# Compress the collected files into a .zip file
if (Test-Path -Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}
Compress-Archive -Path $outputDir\* -DestinationPath $zipFile

# Cleanup - Remove the temporary directory if compression is successful
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
