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
clear

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
Sleep 30

# Creating secret for App "Anywhere 365 Dialogue Cloud - Authentication"
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.ReadWrite.All" -NoWelcome

# Search for the application by its display name
$appName = "Anywhere 365 Dialogue Cloud - Authentication"
$app = Get-MgApplication -Filter "displayName eq '$appName'"
Log-Message "Finding the app $($app) in Entra"

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


Log-Message "Summary of registered applications for $($tenantDomain):"
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

# Display summary of app details
write-host ""
write-host ""
Write-Host "Summary of registered applications for $($tenantDomain):" -ForegroundColor Green
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
