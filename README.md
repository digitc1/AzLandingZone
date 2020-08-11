# Azure Landing Zone

| branch      | status                                                                                         |
| ----------- | ---------------------------------------------------------------------------------------------- |
| master      | ![](https://github.com/digitc1/AzLandingZone/workflows/build/badge.svg?branch=master)             |
| development | ![](https://github.com/digitc1/AzLandingZone/workflows/build/badge.svg?branch=develop)            |

The Landing Zone aims to define a common security baseline for all Cloud projects. The baseline is based on three main pillars:
- Implementing governance rules that prevent users from performing actions considered invalid
- Gather all logs in one place so that they can be analyzed by a Security Operations Center
- Activate the security and availability tools provided by cloud providers

# How to use it
The Azure Landing Zone is provided as a PowerShell module that can be run directly from Azure Shell
1.	Import AzLandingZone module in Azure shell
```
Register-PSRepository -Name "AzLandingZoneRepo" -SourceLocation "https://nuget.pkg.github.com/digitc1/index.json" -publishLocation "https://nuget.pkg.github.com/digitc1/"
Install-Module -Force -Name "AzLandingZone" -Repository "AzLandingZoneRepo"
Import-Module AzLandingZone
```

2.	Run the AzLandingZone module
```
New-AzLandingZone
```
For a complete list of the available parameters, refer to [the specific documentation](docs/New-AzLandingZone.md)

Additional information available on the wiki page:
- https://webgate.ec.europa.eu/fpfis/wikis/display/CVTF/Azure+Secure+Landing+Zone
