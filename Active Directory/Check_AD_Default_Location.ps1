# Check_AD_Default_Location.ps1
# ---------------------------------------------
# This script checks and displays the default Active Directory containers
# for new users and computers in the current domain.
# ---------------------------------------------

Import-Module ActiveDirectory

function Get-ADDefaultContainers {
    Write-Host "Checking default containers for new users and computers in Active Directory..." -ForegroundColor Cyan

    try {
        # Retrieve the default user container
        $userContainer = Get-ADDomain | Select-Object -ExpandProperty UsersContainer
        Write-Host "Default container for new users: $userContainer" -ForegroundColor Green

        # Retrieve the default computer container
        $computerContainer = Get-ADDomain | Select-Object -ExpandProperty ComputersContainer
        Write-Host "Default container for new computers: $computerContainer" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}

Get-ADDefaultContainers
pause