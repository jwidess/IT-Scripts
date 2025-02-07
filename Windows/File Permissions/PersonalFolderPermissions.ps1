# Define the file server's base directory
$baseDir = "\\fnds01\Personnel"

# Prompt for the username
Write-Host "This script will grant the user full control permissions to their user folder" -ForegroundColor Green
Write-Host "Base Directory to Create User Folder in: $baseDir" -ForegroundColor Cyan
$username = Read-Host "Enter the AD logon name such as `"admin`" or `"jon`""

# Construct the user's folder path
$userFolder = Join-Path -Path $baseDir -ChildPath $username
Write-Host "User Folder: $userFolder"
pause

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
    Write-Host "Error assigning permissions: $_" -ForegroundColor Red
    exit
}

# Wait for a few seconds to allow the system to update ACLs
Write-Host "Waiting 5 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

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
    Write-Host "Error retrieving ACLs: $_" -ForegroundColor Red
}

pause