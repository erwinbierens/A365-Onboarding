<#
******************************************************
	        Anywhere365 Onboarding Script
  ______                _ _     _____ _____ _______ 
 |  ____|              (_) |   |_   _/ ____|__   __|
 | |__   ___ _ __  _ __ _| |_    | || |       | |   
 |  __| / __| '_ \| '__| | __|   | || |       | |   
 | |____\__ \ |_) | |  | | |_   _| || |____   | |   
 |______|___/ .__/|_|  |_|\__| |_____\_____|  |_|   
            | |                                     
            |_|           

			            README
******************************************************
.SYNOPSIS
Anywhere365 onboarding script

.Description
This script will create the required App registrations in Entra.

UPDATES:
1.0     > initial setup of the script.

.NOTES
  Version      	   		: 1.0
  Author(s)    			: Erwin Bierens

.EXAMPLE
.\Create-Apps.ps1
#>

# Define Parameters
Param(
    [Parameter(Mandatory = $true)]
    [string]$tenantDomain,
    [Parameter(Mandatory = $true)]
    [string]$customer
)
# Start with a fresh screen
Clear-Host

Write-Host "**** Anywhere365 Onboarding Script ****"
write-host "You will be asked to login multiple times."
write-host ""
Function Log-Message([String]$Message)
{
    [string]$currentdir = Get-Location
	$logfile = "$currentdir\EspritICT-A365-$customer-Log.txt"
	$date = get-date -Format "dd-MM-yyyy"
	$time = get-date -Format "HH:mm:ss"	
	Add-Content -Path $logfile ($date + " " + $time + " " + $Message)
}

$date = Get-Date
Log-Message "--------------------------------------------------------------------------------------------------"
Log-Message "Info : New run for customer $($customer)"

Install-Module -Name Microsoft.Graph.authentication
Install-module -Name Pnp.PowerShell
# Load PnP PowerShell module
Import-Module PnP.PowerShell
Import-Module Microsoft.Graph.Authentication

$app1 = "Anywhere 365 Dialogue Cloud - Ucc Site Creator"
$app2 = "Anywhere 365 Dialogue Cloud - Authentication"
$app3 = "Anywhere 365 Dialogue Cloud - Presence"
$app4 = "Anywhere 365 Dialogue Cloud - PnPApp"

# Register "Anywhere 365 Dialogue Cloud - Ucc Site Creator"
Try {
    $uccSiteCreatorApp = Register-PnPAzureADApp -ApplicationName $app1 -Tenant $tenantDomain -Interactive -SharePointApplicationPermissions "Sites.Selected" -OutPath "$PSScriptRoot\Certs"
    $uccSiteCreatorAppId = $uccSiteCreatorApp.("AzureAppId/ClientId")
    Write-Host "Registered 'Anywhere 365 Dialogue Cloud - Ucc Site Creator' with App ID: $($uccSiteCreatorAppId)"
    Log-Message "Registered 'Anywhere 365 Dialogue Cloud - Ucc Site Creator' with App ID: $($uccSiteCreatorAppId)"
}
Catch {
    write-host "error : Not able to create $($app1)"  -ForegroundColor Red
    Log-Message "error : Not able to create $($app1)"
}

# Register "Anywhere 365 Dialogue Cloud - Authentication"
Try {

    $authApp = Register-PnPAzureADApp -ApplicationName $app2 -Tenant $tenantDomain -Interactive -GraphApplicationPermissions "Sites.FullControl.All" -OutPath "$PSScriptRoot\Certs"
    $authAppId = $authApp.("AzureAppId/ClientId")
    Write-Host "Registered 'Anywhere 365 Dialogue Cloud - Authentication' with App ID: $($authAppId)"
    Log-Message "Registered 'Anywhere 365 Dialogue Cloud - Authentication' with App ID: $($authAppId)"
}
Catch {
    write-host "error : Not able to create $($app2)"  -ForegroundColor Red
    Log-Message "error : Not able to create $($app2)"
}

# Register "Anywhere 365 Dialogue Cloud - Presence"
Try {
    # Define Graph delegate permissions array
    $graphPermissions = @("User.Read.All", "Directory.Read.All", "Presence.Read.All")

    $presenceApp = Register-PnPAzureADApp -ApplicationName $app3 -Tenant $tenantDomain -Interactive -GraphDelegatePermissions $graphPermissions -OutPath "$PSScriptRoot\Certs"
    $presenceAppId = $presenceApp.("AzureAppId/ClientId")
    Write-Host "Registered 'Anywhere 365 Dialogue Cloud - Presence' with App ID: $($presenceAppId)"
    Log-Message "Registered 'Anywhere 365 Dialogue Cloud - Presence' with App ID: $($presenceAppId)"
}
Catch {
    write-host "error : Not able to create $($app3)"  -ForegroundColor Red
    Log-Message "error : Not able to create $($app3)"
}

# Register "Anywhere 365 Dialogue Cloud - PnPApp"
Try {
    $pnpApp = Register-PnPAzureADApp -ApplicationName $app4 -Tenant $tenantDomain -Interactive -GraphDelegatePermissions "Sites.FullControl.All" -OutPath "$PSScriptRoot\Certs"
    $pnpAppId = $pnpApp.("AzureAppId/ClientId")
    Write-Host "Registered 'Anywhere 365 Dialogue Cloud - PnPApp' with App ID: $($pnpAppId)"
    Log-Message "Registered 'Anywhere 365 Dialogue Cloud - PnPApp' with App ID: $($pnpAppId)"
}
Catch {
    write-host "error : Not able to create $($app4)"  -ForegroundColor Red
    Log-Message "error : Not able to create $($app4)"
}

Write-host "Sleeping for 30 seconds.."
Log-Message "Sleeping for 30 seconds.."
Start-Sleep 30

# Creating secret for App "Anywhere 365 Dialogue Cloud - Authentication"
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.Read.All", "User.ReadWrite.All" -NoWelcome

# Search for the application by its display name
$appName = "Anywhere 365 Dialogue Cloud - Authentication"
$app = Get-MgApplication -Filter "displayName eq '$appName'"
Log-Message "Finding the app $($app) in Entra"

# Grab tenant Id from app registration
$tenantId = (Get-MgContext).TenantId

# Check if the app exists and retrieve the App ID
if ($app) {
    $authAppId = $app.Id

    # Define the password credential parameters
    $passwordCred = @{
        displayName = 'Anywhere 365 Dialogue Cloud - Authentication'
        endDateTime = (Get-Date).AddMonths(24)
    }

    # Add a new client secret to the app
    $secret = Add-MgApplicationPassword -ApplicationId $authAppId -PasswordCredential $passwordCred
    Write-Host "Created secret for 'Anywhere 365 Dialogue Cloud - Authentication' with value: $($secret.SecretText)"
    Log-Message "Created secret for 'Anywhere 365 Dialogue Cloud - Authentication' with value: $($secret.SecretText)"
} else {
    Write-Host "Application not found" -ForegroundColor Red
    Log-Message "Application not found"
}

#now let's grab the domains from the tenant:
# Get the domains and filter for the default one
$domains = Get-MgDomain
$defaultDomain = $domains | Where-Object { $_.IsInitial -eq $true }
$initialUserDomain = ($domains | Where-Object { $_.IsInitial -eq $true }).Id
$defaultUserDomain = ($domains | Where-Object { $_.IsDefault -eq $true }).Id

$domainsall = $domains.id

Write-Host "Initial Domain: $($defaultDomain.Id)"
Log-Message "Initial Domain: $($defaultDomain.Id)"

Write-Host "All Domains:"
Write-Host "$($domainsall)"

# Extract the part before '.onmicrosoft.com'
if ($defaultDomain -and $defaultDomain.Id -match "^(.*?)\.onmicrosoft\.com$") {
    $extractedPart = $matches[1]
    Write-Host "Extracted Part: $extractedPart"
} else {
    Write-Host "Default domain does not match the expected pattern"
}

Write-Host "This script requires a password for the Presence Watcher user. Please provide a secure password when prompted." -ForegroundColor Yellow
$presencePwd = Read-Host "Please enter password for the Presence Watcher user.."
Write-Host "This script requires a password for the EC365 Agent user. Please provide a secure password when prompted." -ForegroundColor Yellow
$ec365AgentPwd = Read-Host "Please enter password for the EC365 Agent user.."

#create 2 users
# Define User Data for Both Users
$users = @(
    @{
        displayName = "Anywhere365 Presence Watcher"
        userPrincipalName = "a365-PresenceWatcher@$($initialUserDomain)"
        mailNickname = "a365-PresenceWatcher"
        password = "$presencePwd"
    },
    @{
        displayName = "EC365 Agent"
        userPrincipalName = "ec365.agent@$($defaultUserDomain)"
        mailNickname = "ec365.Agent"
        password = "$ec365AgentPwd"
    }
)

# Step 3: Create Users
foreach ($user in $users) {
    $body = @{
        accountEnabled = $true
        displayName = $user.displayName
        mailNickname = $user.mailNickname
        userPrincipalName = $user.userPrincipalName
        passwordProfile = @{
            forceChangePasswordNextSignIn = $false
            password = $user.password
        }
        passwordPolicies = "DisablePasswordExpiration"
    }

    # Create the user using Microsoft Graph API
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users" -Body ($body | ConvertTo-Json -Depth 10)
    Write-Host "User '$($user.displayName)' created successfully with UPN: $($user.userPrincipalName)"
}


Log-Message "Summary of registered applications for $($tenantDomain):"
Log-Message "Tenant ID: $tenantId"
Log-Message "Initial Domain: $($defaultDomain.Id)"
Log-Message "SharePoint Admin: https://$($extractedPart)-admin.microsoft.com"
Log-Message "SharePoint site: https://$($extractedPart).sharepoint.com"
Log-Message "------------------------------------"
Log-Message "Anywhere 365 Presence User: a365-PresenceWatcher@$($initialDomain)"
Log-Message "Anywhere 365 Presence Pwd : $($presencePwd)"
Log-Message "EC365 Agent User: ec365.agent@$($defaultDomain)"
Log-Message "EC365 Agent Pwd : $($ec365AgentPwd)"
Log-Message "------------------------------------"
Log-Message "$($app1)"
Log-Message "$($uccSiteCreatorAppId)"
Log-Message "------------------------------------"
Log-Message "$($app2)"
Log-Message "$($authAppId)"
Log-Message "Created secret for the app with value: $($secret.SecretText) and EndDate $($secret.EndDateTime)"
Log-Message "------------------------------------"
Log-Message "$($app3)"
Log-Message "$($presenceAppId)"
Log-Message "------------------------------------"
Log-Message "$($app4)"
Log-Message "$($pnpAppId)"
Log-Message "------------------------------------"
Log-Message "Domains for WebAgent allow list:"
Log-Message "$($domainsall)"

# Display summary of app details
write-host ""
write-host ""
Write-Host "Summary of registered applications for $($tenantDomain):" -ForegroundColor Green
Write-Host "Tenant ID: $tenantId"
Write-Host "Initial Domain: $($defaultDomain.Id)"
Write-Host "SharePoint Admin: https://$($extractedPart)-admin.microsoft.com"
Write-Host "SharePoint site: https://$($extractedPart).sharepoint.com"
write-host "------------------------------------"
Write-Host "Anywhere 365 Presence User: a365-PresenceWatcher@$($initialDomain)"
Write-Host "Anywhere 365 Presence Pwd : $($presencePwd)"
Write-Host "EC365 Agent User: ec365.agent@$($defaultDomain)"
Write-Host "EC365 Agent Pwd : $($ec365AgentPwd)"
write-host "------------------------------------"
write-host "$($app1)"
write-host "$($uccSiteCreatorAppId)"
Write-host "NEXT: Upload Self-Signed certificate *.cer file provided by Esprit ICT to app"
write-host "------------------------------------"
write-host "$($app2)"
write-host "$($authAppId)"
Write-Host "Created secret for the app with value: $($secret.SecretText) and EndDate $($secret.EndDateTime)"
write-host "------------------------------------"
write-host "$($app3)"
write-host "$($presenceAppId)"
write-host "------------------------------------"
write-host "$($app4)"
write-host "$($pnpAppId)"
Write-host "NEXT: Upload Self-Signed certificate *.cer file provided by Esprit ICT to app"
write-host "------------------------------------"
Write-Host "Domains for WebAgent allow list:"
Write-host "$($domainsall)"