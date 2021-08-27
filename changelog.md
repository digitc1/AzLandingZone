# Changelog

## fix 1.13.0
Complete refactor of the code base
## fix 1.12.0
Refactor 'Sync-AzLandingZone' cmdlet
## fix 1.11.4
Update diagnostic settings for Azure AD
Fix typo in "setup-policy" script
## fix 1.11.2
Fix typo in "Test-AzLandingZone" cmdlet
## fix 1.11.1
Fix typo in Azure policy name
## release 1.11.0
Add policy to automatically set Azure Hybrid Benefit
## release 1.10.0
Add support for Azure Monitoring Agent and Multi-homing for VM logs
## release 1.9.0
Refactor "Get-AzLandingZone" cmdlet and "Test-AzLandingZone" cmdlet to be compliant with the latest version of the landing zone
## release 1.8.0
Refactor "auto-update" feature to automatically create the RunAs account associated with the automation account
Updated auto-update feature to use Az module instead of AzureRM which will be out of support in coming month
## release 1.7.0
Add missing support for remediation in automation account
Add missing AzureRM.PolicyInsights module in automation account
## release 1.6.0
Create folder structure to automate hunting rules creation by SOC team
Automate the deployment of all analytics rules
## fix 1.5.1
Move all private powershell scripts to /private/PowerShell for sake of clarity for contributors
update auto-update feature to avoid bug creating multiple service principals
## release 1.5.0
Add Sentinel connector for Office365
Update Connector for Azure Security Center (now Azure Defender) and Azure AD (Information Protection)
## release 1.4.0
Build pipeline now uses a custom token to access Azure devops repository
Update of the auto-update feature, this now includes an update of the Azure automation modules to the latest version
## release 1.3.0
Add deployment pipeline
## release 1.2.0
Enable usage of already existing management group
refactor "Test-AzLandingZone" cmdlet to identify unique user
## release 1.1.0
Refactor feature "AzAutomation" (Landing Zone auto-update)
## release 1.0.0
First stable release on Github:
- support for multi-subscription using management groups
- support for Azure resources diagnostic settings using Azure policies and Azure policy definitions
- support for Azure subscription diagnostic settings, Azure security center and Azure tenant using rest-api
- support for Azure lighthouse (delegated access) and Azure Sentinel for DIGIT-S
- support for multiple log collectors (Azure storage account, Azure event-hub, Azure log analytics workspace)

Deployment pipeline using GitHub actions, package repository on Azure DevOps
