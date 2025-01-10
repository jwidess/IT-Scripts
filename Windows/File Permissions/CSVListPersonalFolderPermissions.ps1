Write-Host "This script will grant the list of users full control permissions to their user folder" -ForegroundColor Green

# Define the file server's base directory
$baseDir = "\\fnds01\Personnel"

# Path to the CSV file containing the usernames
# $csvPath = "C:\path\to\your\users.csv"
$csvPath = Read-Host "Enter the path to the CSV File to use (Path only no `"quotes`")"
Write-Host "Path = $csvPath" -ForegroundColor Cyan

# Import the CSV file
$users = Import-Csv -Path $csvPath

# Display the list of users from the CSV file
Write-Host "---------------------------------------"
Write-Host "Users to be processed:" -ForegroundColor Cyan
$users | ForEach-Object { Write-Host $_.username }
Write-Host "---------------------------------------"
# Prompt to continue
$confirmation = Read-Host "Do you want to continue processing these users? (Y/N)"
if ($confirmation -ne "Y") {
    Write-Host "Operation canceled." -ForegroundColor Red
    exit
}

# Loop through each user in the CSV file
foreach ($user in $users) {
    $username = $user.username
	Write-Host "---------------------------------------"
    Write-Host "Processing user: $username" -ForegroundColor Blue

    # Construct the user's folder path
    $userFolder = Join-Path -Path $baseDir -ChildPath $username
    Write-Host "User Folder: $userFolder"

    # Check if the folder exists
    if (!(Test-Path -Path $userFolder)) {
        Write-Host "Folder does not exist. Creating folder..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $userFolder | Out-Null
        Write-Host "Folder created: $userFolder" -ForegroundColor Green
    } else {
        Write-Host "Folder already exists: $userFolder" -ForegroundColor Cyan
    }

    # Assign full control permissions to the user
    try {
        Write-Host "Domain and Username: $env:USERDOMAIN\$username" -ForegroundColor Cyan
        $acl = Get-Acl -Path $userFolder
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$env:USERDOMAIN\$username",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $userFolder -AclObject $acl

        Write-Host "Full control permissions granted to $username on $userFolder" -ForegroundColor Green
    } catch {
        Write-Host "Error assigning permissions for $username : $_" -ForegroundColor Red
    }

    # Wait for a few seconds to allow the system to update ACLs
    Start-Sleep -Seconds 2

    # Retrieve and display the ACLs to verify
    try {
        $updatedAcl = Get-Acl -Path $userFolder
        Write-Host "Updated ACLs for $userFolder :" -ForegroundColor Cyan
        $updatedAcl.Access | ForEach-Object {
            Write-Host "Identity: $($_.IdentityReference)"
            Write-Host "Access Control Type: $($_.AccessControlType)"
            Write-Host "Permissions: $($_.FileSystemRights)"
            Write-Host "Inheritance: $($_.InheritanceFlags)"
            Write-Host "Propagation: $($_.PropagationFlags)"
            Write-Host "--------------------------------------------"
        }
    } catch {
        Write-Host "Error retrieving ACLs for $userFolder : $_" -ForegroundColor Red
    }
}

pause