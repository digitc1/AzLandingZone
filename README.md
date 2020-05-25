# Introduction 
This PowerShell modules allows to implement the Landing Zone as define by DIGIT.C1 and DIGIT.S in Azure environments

# Getting Started
1.	Import AzLandingZone module in Azure shell
- Register-PSRepository -Name "AzLandingZoneRepo" -SourceLocation "https://pkgs.dev.azure.com/devops0837/LandingZonePublic/_packaging/publicfeed/nuget/v2" -publishLocation "https://pkgs.dev.azure.com/devops0837/LandingZonePublic/_packaging/publicfeed/nuget/v2"
- Install-Module -Force -Name "AzSentinel"
- Import-Module AzSentinel
- Install-Module -Force -Name "Az.Security"
- Import-Module Az.Security
- Install-Module -Force -Name "AzLandingZone" -Repository "AzLandingZoneRepo"
- Import-Module AzLandingZone
2.	Run the AzLandingZone module
- New-AzLandingZone -SOC "DIGIT" -autoupdate $true -location "westeurope"

Additional information available on the wiki page:
- https://webgate.ec.europa.eu/fpfis/wikis/display/CVTF/Azure+Secure+Landing+Zone
