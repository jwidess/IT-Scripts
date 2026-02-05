# Get_Disk_Info.ps1
# ---------------------------------------------
# This script gathers detailed disk information using PowerShell and smartctl (smartmontools).
# Compatible with PowerShell 5+
# Information collected includes:
#   - Disk Info: Number, Model, Serial, Size, Partition Style (MBR/GPT), Bus Type
#   - Physical Disk Health via smartctl (SMART data)
#   - Partition Info: Number, Drive Letter, Type
#   - Volume Info: Label, File System, Total Size, Used Space, Free Space, % Free
# Usage:
#   - Run this script with administrative privileges.
#   - Requires 'smartmontools' to be installed and 'smartctl' to be in the system PATH.
# ---------------------------------------------

# Check for admin privs
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "This script must be run as Administrator!" -ForegroundColor Red
  Write-Host "Right-click the script and select 'Run with PowerShell (Admin)' or run from an elevated PowerShell window." -ForegroundColor Yellow
  pause
  exit
}

# Check for smartctl
$SmartCtlPath = Get-Command "smartctl" -ErrorAction SilentlyContinue
if (-not $SmartCtlPath) {
    Write-Warning "smartctl.exe (smartmontools) not found in PATH."
    Write-Warning "SMART data will be unavailable. Please install smartmontools."
    Write-Warning "Install from: https://github.com/smartmontools/smartmontools/releases"
}

try {
    # Get all physical disks
    $Disks = Get-Disk | Sort-Object Number
}
catch {
    Write-Error "Failed to retrieve disk information. Ensure the Storage module is available."
    exit
}

$VolumeReport = @()
$DriveHealthReport = @()

foreach ($Disk in $Disks) {
    # 1. Volume & Partition Information
    $Partitions = Get-Partition -DiskNumber $Disk.Number -ErrorAction SilentlyContinue
    
    if ($Partitions) {
        foreach ($Partition in $Partitions) {
            $Volume = $null
            try { $Volume = $Partition | Get-Volume -ErrorAction Stop } catch {}

            $VolSizeGB = $null; $VolFreeGB = $null; $VolPercentFree = $null
            if ($Volume) {
                $VolSizeGB = [math]::Round($Volume.Size / 1GB, 2)
                $VolFreeGB = [math]::Round($Volume.SizeRemaining / 1GB, 2)
                if ($Volume.Size -gt 0) {
                    $VolPercentFree = [math]::Round(($Volume.SizeRemaining / $Volume.Size) * 100, 1)
                }
            }

            $VolumeReport += [PSCustomObject]@{
                DiskNum       = $Disk.Number
                Drive         = if ($Partition.DriveLetter) { $Partition.DriveLetter } else { "" }
                Label         = if ($Volume) { $Volume.FileSystemLabel } else { "" }
                FileSystem    = if ($Volume) { $Volume.FileSystem } else { "" }
                SizeGB        = $VolSizeGB
                FreeGB        = $VolFreeGB
                PercentFree   = $VolPercentFree
                PartStyle     = $Disk.PartitionStyle
                Model         = $Disk.Model
            }
        }
    }
    else {
        # Unpartitioned Disk
        $VolumeReport += [PSCustomObject]@{
            DiskNum       = $Disk.Number
            Drive         = ""
            Label         = "(Unpartitioned)"
            FileSystem    = ""
            SizeGB        = [math]::Round($Disk.Size / 1GB, 2)
            FreeGB        = $null
            PercentFree   = $null
            PartStyle     = $Disk.PartitionStyle
            Model         = $Disk.Model
        }
    }

    # 2. SMART Health (smartctl)
    
    # Default values
    $SmartStatus = "Unknown"
    $TempC = $null
    $PowerHours = $null
    $Reallocated = $null
    $WearLevel = $null
    $WrittenData = $null
    $Serial = $Disk.SerialNumber
    $Model = $Disk.Model
    $Family = ""
    $DeviceType = "Unknown"

    if ($SmartCtlPath) {
        # Windows Disk Number to smartctl device path: /dev/pd<N>
        $DevicePath = "/dev/pd$($Disk.Number)"
        
        try {
            # Run smartctl JSON output (-j) all info (-a)
            # 2>&1 catch output even if exit code is non zero
            $SmartJson = & smartctl -j -a $DevicePath 2>&1 | Out-String | ConvertFrom-Json
            
            if ($SmartJson) {
                # Basic Info
                if ($SmartJson.device.protocol) { $DeviceType = $SmartJson.device.protocol } 
                elseif ($SmartJson.device.type) { $DeviceType = $SmartJson.device.type }

                if ($SmartJson.model_name) { $Model = $SmartJson.model_name }
                if ($SmartJson.serial_number) { $Serial = $SmartJson.serial_number }
                if ($SmartJson.model_family) { $Family = $SmartJson.model_family }
                
                # Health Status
                if ($SmartJson.smart_status.passed -eq $true) {
                    $SmartStatus = "PASSED"
                } elseif ($SmartJson.smart_status.passed -eq $false) {
                    $SmartStatus = "FAILED"
                }

                # Temperature
                if ($SmartJson.temperature.current) { $TempC = $SmartJson.temperature.current }

                # Power On Hours
                if ($SmartJson.power_on_time.hours) { $PowerHours = $SmartJson.power_on_time.hours }

                # --- Vendor Specific / Critical Attributes ---
                
                # Check for ATA Attributes
                if ($SmartJson.ata_smart_attributes.table) {
                    # ID 5: Reallocated Sector Count
                    $AttRealloc = $SmartJson.ata_smart_attributes.table | Where-Object { $_.id -eq 5 }
                    if ($AttRealloc) { $Reallocated = $AttRealloc.raw.value }
                    
                    # ID 241: Total LBAs Written (Common for SATA SSDs)
                    $AttWritten = $SmartJson.ata_smart_attributes.table | Where-Object { $_.id -eq 241 }
                    if ($AttWritten) { 
                        # Assume 512b sectors for Total_LBAs_Written
                        $Bytes = [math]::BigMul($AttWritten.raw.value, 512)
                        $WrittenData = if ($Bytes -gt 1TB) { "{0:N1} TB" -f ($Bytes / 1TB) } else { "{0:N1} GB" -f ($Bytes / 1GB) }
                    }

                    # SSD Wear (Various IDs: 177, 233, etc.)
                    $AttWear = $SmartJson.ata_smart_attributes.table | Where-Object { $_.id -in 177, 230, 231, 233, 241 } # Common SSD life attributes
                    if ($AttWear) { $WearLevel = "Raw: " + ($AttWear | Select-Object -First 1).raw.string } 
                }

                # Check for NVMe Log
                if ($SmartJson.nvme_smart_health_information_log) {
                    $NvmeLog = $SmartJson.nvme_smart_health_information_log
                    # Percentage Used
                    if ($NvmeLog.percentage_used -ne $null) {
                        $WearLevel = "$($NvmeLog.percentage_used)% Used"
                    }
                    # Data Units Written (1 unit = 1000 * 512 bytes = 512,000 bytes)
                    if ($NvmeLog.data_units_written -ne $null) {
                        $Bytes = [decimal]$NvmeLog.data_units_written * 512000
                        $WrittenData = if ($Bytes -gt 1TB) { "{0:N2} TB" -f ($Bytes / 1TB) } else { "{0:N2} GB" -f ($Bytes / 1GB) }
                    }
                    if ($NvmeLog.critical_warning -gt 0) {
                        $SmartStatus = "WARNING (NVMe Crit)"
                    }
                }
            }
        }
        catch {
            $SmartStatus = "Error/No Data"
        }
    }

    $DriveHealthReport += [PSCustomObject]@{
        DiskNum       = $Disk.Number
        SmartStatus   = $SmartStatus
        Model         = $Model
        Type          = $DeviceType
        SerialNumber  = $Serial
        TempC         = $TempC
        PowerHours    = $PowerHours
        Reallocated   = $Reallocated
        WearLevel     = $WearLevel
        Written       = $WrittenData
    }
}

# OUTPUT

Write-Host "`n=== VOLUME INFORMATION (Partitions & Usage) ===" -ForegroundColor Cyan
$VolumeReport | Format-Table -AutoSize -Property DiskNum, Drive, Label, FileSystem, SizeGB, FreeGB, PercentFree, PartStyle

Write-Host "`n=== PHYSICAL DRIVE HEALTH (Via smartctl) ===" -ForegroundColor Cyan
if ($SmartCtlPath) {
    $DriveHealthReport | Format-Table -AutoSize -Property DiskNum, SmartStatus, TempC, Reallocated, WearLevel, Written, PowerHours, Type, Model, SerialNumber
} else {
    Write-Warning "Smartctl not available. Install smartmontools to view Health/SMART data table."
}

pause