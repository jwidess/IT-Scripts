# Script to gather system and domain information, and compress it into a .zip file

# Define output directory and files
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = "$scriptDir\SystemInfo"
$shortDate = (Get-Date -Format "MM-dd-yyyy")
$computerName = $env:COMPUTERNAME
$zipFile = $scriptDir + "\" + "SystemInfo_" + $computerName + "_" + $shortDate + ".zip"

# Ensure the output directory exists
if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Gather domain and group policy information
$gpResultFile = "$outputDir\GPResult.html"
gpresult /H $gpResultFile

# Gather hardware information
$hardwareInfoFile = "$outputDir\HardwareInfo.txt"
Get-CimInstance -ClassName Win32_ComputerSystem | Out-File -Append $hardwareInfoFile
Get-CimInstance -ClassName Win32_Processor | Out-File -Append $hardwareInfoFile
Get-CimInstance -ClassName Win32_PhysicalMemory | Out-File -Append $hardwareInfoFile

# Gather network configuration
$networkInfoFile = "$outputDir\NetworkInfo.txt"
ipconfig /all | Out-File -Append $networkInfoFile
route print | Out-File -Append $networkInfoFile

# Gather operating system information
$osInfoFile = "$outputDir\OSInfo.txt"
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Version, Caption | Out-File $osInfoFile
Get-ComputerInfo | Out-File -Append $osInfoFile

# Compress the collected files into a .zip file
if (Test-Path -Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}
Compress-Archive -Path $outputDir\* -DestinationPath $zipFile

# Cleanup - Remove the temporary directory if compression is successful
if (Test-Path -Path $zipFile) {
    Remove-Item -Path $outputDir -Recurse -Force
}

Write-Host "----------------------------"
Write-Host "Information has been gathered and saved to $zipFile" -ForegroundColor Green
Write-Host "----------------------------"
pause
