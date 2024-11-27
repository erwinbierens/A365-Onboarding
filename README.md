# Anywhere365 Onboarding
This script will create 4 App registrations in your Microsoft 365 tenant:
* Anywhere 365 Dialogue Cloud - Ucc Site Creator
* Anywhere 365 Dialogue Cloud - Authentication
* Anywhere 365 Dialogue Cloud - Presence
* Anywhere 365 Dialogue Cloud - PnPApp

For each app, the script will set the corresponding rights for graph or SharePoint. Granting consent is required.

After creating the Apps, a secret value will be created for 24 months for the Authentication App. 

The script will also create 2 new acocunts. 
* Presence Watcher for Anywhere365
* EC365 Agent (Test User)

## Requirements

* PowerShell 7 (Link)[https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4]
* Microsoft365 Global Admin Rights
* 1, E1/E3 with Phone System or E5 License

## Run script
Make sure to set your execution policy for this script.

    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

**Run script:**
The required role in Microsft 365 to create Apps and users is Global Admin.

    .\Create-Apps.ps1

## After running the scripts
After running the scripts, please provide your Esprit ICT consultant the Certs and log file. 

**ToDo** 
* Assign License to EC365 Agent user (E1/E3 with Phone System or E5)
* Assign Cert (Provided by consultant) to the Ucc Site Creator and PnPApp. 
* Exclude Presence Watcher user from MFA