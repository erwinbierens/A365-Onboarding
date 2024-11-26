# README
This script will create 4 App registrations in your Microsoft 365 tenant:
* Anywhere 365 Dialogue Cloud - Ucc Site Creator
* Anywhere 365 Dialogue Cloud - Authentication
* Anywhere 365 Dialogue Cloud - Presence
* Anywhere 365 Dialogue Cloud - PnPApp

For each app, the script will set the corresponding rights for graph or SharePoint. Granting consent is required.

After creating the Apps, a secret value will be created for 24 months for the Authentication App. 

Run script: 
.\Create-Apps.ps1

After running the scripts, please provide your Esprit ICT consultant the Certs and log file. 
The required role to create scripts is Global Admin.
