# Get_WSL_info.ps1
# ---------------------------------------------
# This script gathers information about the Windows Subsystem for Linux (WSL) installation,
# including the status of WSL features and installed distributions.
# ---------------------------------------------

function Get-WSLInfo {
    [CmdletBinding()]
    param()

    Write-Host "Gathering WSL Information..." -ForegroundColor Cyan
    Write-Host "--------------------------------" -ForegroundColor Gray

    # Check if wsl is available in path
    $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue

    if (-not $wslCommand) {
        Write-Warning "WSL Executable (wsl.exe) not found in system PATH."
        Write-Host "Please ensure Windows Subsystem for Linux is installed."
        return
    }

    Write-Host "WSL Executable found at: $($wslCommand.Source)" -ForegroundColor Green

    # Check BIOS Virtualization
    try {
        $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        
        if ($cpuInfo.PSObject.Properties['VirtualizationFirmwareEnabled']) {
             $virtEnabled = $cpuInfo.VirtualizationFirmwareEnabled
             $virtColor = if ($virtEnabled) { 'Green' } else { 'Red' }
             Write-Host "BIOS Virtualization Enabled: $virtEnabled" -ForegroundColor $virtColor
        } else {
             Write-Host "BIOS Virtualization Status: Unknown (Property not available)" -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Could not determine BIOS Virtualization status. $_"
    }

    # Check Windows Optional Feature (Requires Admin)
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        try {
            $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction Stop
            $wslColor = if ($wslFeature.State -eq 'Enabled') { 'Green' } else { 'Yellow' }
            Write-Host "WSL Optional Feature State: $($wslFeature.State)" -ForegroundColor $wslColor
            
            $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
            if ($vmpFeature) {
                $vmpColor = if ($vmpFeature.State -eq 'Enabled') { 'Green' } else { 'Yellow' }
                Write-Host "Virtual Machine Platform State: $($vmpFeature.State)" -ForegroundColor $vmpColor
            }
        }
        catch {
            Write-Warning "Could not query Windows Optional Features. $_"
        }
    } else {
        Write-Host "Skipping specific feature check (requires Administrator privileges)." -ForegroundColor Gray
    }

    # Check WSL Status (wsl --status)
    Write-Host "`n--- WSL Status ---" -ForegroundColor White
    $wslStatusSuccess = $false
    try {
        $statusOutput = wsl.exe --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            $statusOutput | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
            $wslStatusSuccess = $true
        } else {
            Write-Host "Could not retrieve detailed status (wsl --status returned no info or failed)." -ForegroundColor Yellow
            Write-Host "Output: $($statusOutput | Out-String)" -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "Failed to run 'wsl --status'."
    }

    if (-not $wslStatusSuccess) {
        Write-Warning "WSL does not appear to be correctly installed or running. Skipping distribution list."
        return
    }

    # Check Installed Distributions (wsl --list --verbose)
    Write-Host "`n--- Installed Distributions ---" -ForegroundColor White
    try {
        # wsl.exe output encoding is annoying
        $listOutput = wsl.exe --list --verbose
        
        # Filter out empty lines
        $lines = $listOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        # Check for valid list header to avoid parsing help text or error messages
        $headerFound = $false
        foreach ($line in $lines) {
            # Remove null bytes
            $cleanLine = $line -replace '\x00', ''
            
            # Check if line looks like a header using wildcards
            if ($cleanLine -like "*NAME*STATE*") {
                $headerFound = $true
                break
            }
        }

        if (-not $headerFound) {
            Write-Host "It appears no distributions are installed or the output format is unexpected." -ForegroundColor Yellow
            Write-Host "Raw Output:" -ForegroundColor DarkGray
            $lines | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
            # Helper message if it looks like help text
            if ($lines -join "`n" -like "*--install*") {
                 Write-Host "`nUse 'wsl.exe --install' to install default distribution." -ForegroundColor Cyan
            }
            return
        }

        if ($lines.Count -le 1) {
            # Try listing if verbose fails or returns bad
            if ($lines.Count -eq 0) {
                 Write-Host "No output for distribution list." -ForegroundColor Yellow
            } else {
                 # Maybe header only?
                 Write-Host "No distributions appear to be installed." -ForegroundColor Yellow
            }
        }
        else {
            $distroObjects = @()
            
            # Skip the header row (row 0)
            for ($i = 1; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                
                # Check for default marker '*'
                $isDefault = $false
                if ($line.TrimStart().StartsWith("*")) {
                    $isDefault = $true
                    $line = $line.Replace("*", " ") # Replace first * with space
                }
                
                # Remove control chars (including nulls) and replace weird whitespace with space
                $line = $line -replace '\x00', '' -replace '[\p{C}]', '' -replace '[\p{Z}]', ' '
                $line = $line.Trim()
                
                if ([string]::IsNullOrWhiteSpace($line)) { continue }

                # Split by whitespace and filter empty entries
                $parts = $line -split ' +' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                
                # Expected output: Name, State, Version
                if ($parts.Count -ge 3) {
                    $distroObjects += [PSCustomObject]@{
                        'IsDefault' = $isDefault
                        'Name'      = $parts[0]
                        'State'     = $parts[1]
                        'Version'   = $parts[2]
                    }
                }
            }
            
            if ($distroObjects.Count -gt 0) {
                # Display properties list
                $distroObjects | Format-Table -AutoSize
            } else {
                Write-Host "No valid distributions found in output." -ForegroundColor Yellow
                Write-Host "Raw Output associated with parsing failure:" -ForegroundColor DarkGray
                $lines | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
            }
        }

    } catch {
        Write-Warning "Failed to retrieve distribution list. $_"
    }
}

Get-WSLInfo

pause