# Import Active Directory module
Import-Module ActiveDirectory

# Function to get default containers
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

# Execute the function
Get-ADDefaultContainers
pause