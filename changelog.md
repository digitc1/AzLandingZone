# Changelog
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