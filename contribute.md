# Contributing
This code repository is open for external contributions.
When contributing to the repository, please first discuss the change you wish to make via issue with the owners of this repository before making any change. The issue must be tagged with "bug" for bugfixes or "enhancement" for feature requests.

Please note that any submitted code (bugfixes or enhancement) will be reviewed by the maintainer before merging.

## Pull Request Process
1. Create a branch from develop which name is "bugfix/issueX" or "feature/issueX". The feature or bugfix must be validated locally before any pull request
2. Publish your branch to GitHub repository. The commit must include in description which will be used to update the changelog.
3. The maintainer will merge the code, update release version and update the changelog based on commit's description.

## Project structure
This project follows the default project structure for nuget package. This is composed of 4 repositories and multiple information files:
- .github/workflows repository contains all the workflows (GitHub actions) used in the project.
- build repository contains all build scripts used in GitHub workflow to build the project.
- docs repository contains all the documentation related to the project.
- multiple information files (readme, contribution guide, changelog, ...)
- <project>/Public and <project>/Private are actual code repository that will be packed and public using NuGet. Code contribution should always happen in this repository.

As per convention, the <project> repository is divided in 2 parts, Public and Private. The Public repository contains all the functions that will be publicly exposed (e.g. New-AzLandingZone, Get-AzLandingZone, ...) while private repository contains all the script and functions that are used in the backend to deploy or update the resources. This Private repository structure may vary depending on the project's specific need.
For sake of clarity, the following structure has been put in place for Azure Landing Zone projects:
- PowerShell repository contains all PowerShell functions
- rest-api repository contains a set of script that performs a rest-api call to Azure management endpoint. In this repository, all functions are sorted based on the functionality to update (subscription, security center, tenant, ...)