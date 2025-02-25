#Requires -Version 7.4.6
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

******************************************************
.SYNOPSIS
Anywhere365 onboarding script

.Description
This script will create the required App registrations in Entra.

UPDATES:
1.0    > initial setup of the script.
1.01   > Added logging to a log file.
1.02   > Added the extra Graph Powershell modules.
1.03   > added check for powershell modules and install them if not present.
1.04   > added Enterprise App links for Anywhere Attendant Console and Core configurations.
1.05   > changed the Graph API module to Microsoft.Graph. Added Certificates directorty creation.

.NOTES
  Version      	   		: 1.05
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

Write-Host "**** Anywhere365 Onboarding Script ****" -ForegroundColor Cyan
Write-host "This script will create all nessasary app registrations and accounts.."
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

# Define the directory path
$LogDirectory = ".\Certificates"

# Check if the directory exists
if (-not (Test-Path -Path $LogDirectory)) {
    # Create the directory
    New-Item -Path $LogDirectory -ItemType Directory -Force
    Write-Host "Directory 'Certificates' created successfully."
} else {
    Write-Host "Directory 'Certificates' already exists."
}

Log-Message "--------------------------------------------------------------------------------------------------"
Log-Message "Info : New run for customer $($customer)"



# List of modules to install with required versions
$modules = @(
    @{ Name = 'Microsoft.Graph'; Version = '2.25.0' },
    @{ Name = 'PnP.PowerShell'; Version = '2.12.0' }
)

# Install or update each module if necessary
foreach ($module in $modules) {
    $installedModule = Get-Module -ListAvailable -Name $module.Name | Sort-Object Version -Descending | Select-Object -First 1
    
    if (-not $installedModule) {
        # Module not installed, install it
        Install-Module -Name $module.Name -RequiredVersion $module.Version -Scope CurrentUser -Force
        Write-Host "Installed module: $($module.Name) version $($module.Version)"
    } elseif ($installedModule.Version -lt [version]$module.Version) {
        #first uninstall all modules:
        Uninstall-Module Microsoft.Graph -AllVersions -Force
        # Installed version is older, update the module
        Install-Module -Name $module.Name -RequiredVersion $module.Version -Scope CurrentUser -Force
        Write-Host "Updated module: $($module.Name) to version $($module.Version)"
        Write-host -ForegroundColor yellow "Please restart the script to activate the new modules"
        exit 1
    } else {
        # Installed version is up-to-date
        Write-Host "Module $($module.Name) is already up-to-date (version $($installedModule.Version))"
    }
}



# List of modules to install
#$modules = @('Microsoft.Graph.authentication', 'PnP.PowerShell', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Identity.DirectoryManagement')


# Install each module if it's not already installed
# foreach ($module in $modules) {
#    if (-not (Get-Module -ListAvailable -Name $module)) {
#        Install-Module -Name $module -Scope CurrentUser -Force
#        Write-Host "Installed module: $module"
#    } else {
#        Write-Host "Module already installed: $module"
#    }
#}

# Load PnP PowerShell module
Import-Module PnP.PowerShell
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Applications


$app1 = "Anywhere 365 Dialogue Cloud - Ucc Site Creator"
$app2 = "Anywhere 365 Dialogue Cloud - Authentication"
$app3 = "Anywhere 365 Dialogue Cloud - Presence"
$app4 = "Anywhere 365 Dialogue Cloud - PnPApp"

# Register "Anywhere 365 Dialogue Cloud - Ucc Site Creator"
Try {
    $uccSiteCreatorApp = Register-PnPAzureADApp -ApplicationName $app1 -Tenant $tenantDomain -Interactive -SharePointApplicationPermissions "Sites.Selected" -OutPath "$PSScriptRoot\Certificates"
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

    $authApp = Register-PnPAzureADApp -ApplicationName $app2 -Tenant $tenantDomain -Interactive -GraphApplicationPermissions "Sites.FullControl.All" -OutPath "$PSScriptRoot\Certificates"
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

    $presenceApp = Register-PnPAzureADApp -ApplicationName $app3 -Tenant $tenantDomain -Interactive -GraphDelegatePermissions $graphPermissions -OutPath "$PSScriptRoot\Certificates"
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

    $graphPermissions = @("User.Read.All", "Sites.FullControl.All", "Group.ReadWrite.All")
    $graphSPAppPermissions = @("User.ReadWrite.All", "Sites.FullControl.All")
    $graphSPDelAppPermissions = @("AllSites.FullControl")

    $pnpApp = Register-PnPAzureADApp -ApplicationName $app4 -Tenant $tenantDomain -Interactive -GraphApplicationPermissions $graphPermissions -SharePointApplicationPermissions $graphSPAppPermissions -SharePointDelegatePermissions $graphSPDelAppPermissions -OutPath "$PSScriptRoot\Certificates"
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
Log-Message "All Domains:"
Log-Message "$($domainsall)"

# Extract the part before '.onmicrosoft.com'
if ($defaultDomain -and $defaultDomain.Id -match "^(.*?)\.onmicrosoft\.com$") {
    $extractedPart = $matches[1]
    Write-Host "Extracted Part: $extractedPart"
} else {
    Write-Host "Default domain does not match the expected pattern"
    Log-Message "Default domain does not match the expected pattern"
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

Write-Host "Opening browser with Enterprise App for Anywhere365 Core configurations"
$clientId = "b087e5fb-3463-46b7-a74d-047a9dee095d"
$url = "https://login.microsoftonline.com/common/adminconsent?client_id=$clientId"
 
# Open the URL in the default browser
Start-Process -FilePath $url

Write-Host "Opening browser with Enterprise App for Anywhere365 Attendant Console"
$clientId = "b49e1919-ca4f-4a60-bae4-24bb7b231f97"
$url = "https://login.microsoftonline.com/common/adminconsent?client_id=$clientId"
 
# Open the URL in the default browser
Start-Process -FilePath $url


Log-Message "Summary of registered applications for $($tenantDomain):"
Log-Message "Tenant ID: $tenantId"
Log-Message "Initial Domain: $($defaultDomain.Id)"
Log-Message "SharePoint Admin: https://$($extractedPart)-admin.microsoft.com"
Log-Message "SharePoint site: https://$($extractedPart).sharepoint.com"
Log-Message "------------------------------------"
Log-Message "Anywhere 365 Presence User: a365-PresenceWatcher@$($initialUserDomain)"
Log-Message "Anywhere 365 Presence Pwd : $($presencePwd)"
Log-Message "EC365 Agent User: ec365.agent@$($defaultUserDomain)"
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
Write-Host "Summary of registered applications for $($tenantDomain):" -ForegroundColor Cyan
write-host ""
Write-Host "Tenant ID: $tenantId"
Write-Host "Initial Domain: $($defaultDomain.Id)"
Write-Host "SharePoint Admin: https://$($extractedPart)-admin.sharepoint.com"
Write-Host "SharePoint site: https://$($extractedPart).sharepoint.com"
write-host "------------------------------------"
Write-Host "Anywhere 365 Presence User: a365-PresenceWatcher@$($initialUserDomain)"
Write-Host "Anywhere 365 Presence Pwd : $($presencePwd)"
Write-Host "EC365 Agent User: ec365.agent@$($defaultUserDomain)"
Write-Host "EC365 Agent Pwd : $($ec365AgentPwd)"
write-host "------------------------------------"
write-host "$($app1)"
write-host "$($uccSiteCreatorAppId)"
Write-host "NEXT: Upload Self-Signed certificate *.cer file provided by Esprit ICT to app" -ForegroundColor Yellow
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
Write-host "NEXT: Upload Self-Signed certificate *.cer file provided by Esprit ICT to app" -ForegroundColor Yellow
write-host "------------------------------------"
Write-Host "Domains for WebAgent allow list:"
Write-host "$($domainsall)"
write-host ""
write-host ""
write-host ""
write-host "TODO: Add a365-PresenceWatcher@$($initialUserDomain) to MFA Exclusion" -ForegroundColor Yellow
