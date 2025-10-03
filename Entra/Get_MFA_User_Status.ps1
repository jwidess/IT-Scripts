## ===============================
# Get_MFA_User_Status.ps1
# This script retrieves the MFA status of users in Microsoft Entra ID
# and exports the results to a CSV file.
## ===============================

# Ensure Microsoft Graph is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
   Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Define required Graph scopes
$requiredScopes = @(
    "User.Read.All",
    "Directory.Read.All",
    "UserAuthenticationMethod.Read.All"
)

# Connect to Graph with required scopes
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $requiredScopes

# Confirm login
$context = Get-MgContext
if ($context.Account -and $context.Scopes -contains "UserAuthenticationMethod.Read.All") {
    Write-Host "Connected as $($context.Account) with necessary scopes." -ForegroundColor Green
} else {
    Write-Warning "Failed to connect with the required scopes."
    Exit
}

# Define auth methods that indicate MFA is set up
$authTypesRequiringMFA = @(
    "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod",
    "#microsoft.graph.fido2AuthenticationMethod",
    "#microsoft.graph.phoneAuthenticationMethod",
    "#microsoft.graph.softwareOathAuthenticationMethod",
    "#microsoft.graph.temporaryAccessPassAuthenticationMethod"
)

Write-Host "Retrieving users from Microsoft Graph..." -ForegroundColor Cyan
$users = Get-MgUser -Filter "accountEnabled eq true" | Select-Object UserPrincipalName, Id
Write-Host ("Found {0} Enabled users. Gathering MFA status, this may take a while..." -f $users.Count) -ForegroundColor Yellow

$userCount = $users.Count
$current = 0
$results = foreach ($user in $users) {
    $current++
    Write-Host ("Processing user {0}/{1}: {2}" -f $current, $userCount, $user.UserPrincipalName) -ForegroundColor DarkGray
    $methods = Get-MgUserAuthenticationMethod -UserId $user.Id

    $odataTypes = @()

    if ($methods) {
        foreach ($m in $methods) {
            $type = $m.AdditionalProperties['@odata.type']
            if (-not $type) { $type = $m.'@odata.type' }
            if ($type) { $odataTypes += $type }
        }
    }

    $hasMfa = $odataTypes | Where-Object { $_ -in $authTypesRequiringMFA }

    $cleanedTypes = $odataTypes | ForEach-Object { $_ -replace '^#microsoft\.graph\.' }
    [PSCustomObject]@{
        User = $user.UserPrincipalName
        MFA_Registered = if ($hasMfa) { "Yes" } else { "No" }
        Methods = ($cleanedTypes -join ", ")
    }
}

${dateStr} = Get-Date -Format 'yyyy-MM-dd'
$csvPath = ".\MFA-Audit-$dateStr.csv"
Write-Host ("Exporting results to {0}..." -f $csvPath) -ForegroundColor Cyan
$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Sort the CSV by MFA_Registered, putting "No" first
$sortedResults = Import-Csv -Path $csvPath | Sort-Object @{Expression='MFA_Registered'; Descending=$false}, @{Expression='User'; Descending=$false}
$sortedResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host ("Done! Results saved to {0}" -f $csvPath) -ForegroundColor Green

pause