Function setup-Policy {
    param(
        [Parameter(Mandatory = $true)][string]$name
    )

    #
    # External resource required
    #
    $definitionListv1URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList1.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionParametersv1URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2Fparameters1.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionListv2URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList2.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionParametersv2URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2Fparameters2.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionListv3URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2FdefinitionList3.txt&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionParametersv3URI = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2Fparameters3.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionSecurityCenterCoverage = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2Fdefinition-securityCenterCoverage.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"
    $definitionSecurityCenterAutoProvisioning = "https://dev.azure.com/devops0837/LandingZonePublic/_apis/git/repositories/LandingZonePublic/items?path=%2FLandingZone%2Fdefinitions%2Fdefinition-securityCenterAutoProvisioning.json&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=master&resolveLfs=true&%24format=octetStream&api-version=5.0&download=true"

    #
    # Create variables needed for this script
    #
    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object { $_.StorageAccountName -Like "*$name*" })) {
        Write-Host "No Storage Account found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group" -Expand | Where-Object { $_.Name -Like "lz-management-group" })) {
        Write-Host "No Management group found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    $location = $GetResourceGroup.Location
    $scope = ($GetManagementGroup).Id

    #
    # Creating policy definition related to Azure Security Center
    #
    Write-Host "Checking registration for Azure Security Center CIS Benchmark" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "ASC_Default" })) {
        Write-Host "Enabling first monitoring in Azure Security Center"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ 'Enable Monitoring in Azure Security Center' }
        New-AzPolicyAssignment -Name "ASC_Default" -DisplayName "Azure Security Center - Default" -PolicySetDefinition $Policy -Scope $scope | Out-Null
    }
    Write-Host "Checking registration for extended Azure Security Center CIS Benchmark" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "ASC_CIS" })) {
        Write-Host "Enabling second monitoring in Azure Security Center"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ 'CIS Microsoft Azure Foundations Benchmark 1.1.0' }
        New-AzPolicyAssignment -Name "ASC_CIS" -DisplayName "Azure Security Center - CIS Compliance" -PolicySetDefinition $Policy -Scope $scope -listOfRegionsWhereNetworkWatcherShouldBeEnabled $location | Out-Null
    }
    Write-Host "Checking policy for Azure Security Center coverage" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCCoverage" })) {
        Write-Host "Enabling Azure Security Center coverage"
        Invoke-WebRequest -Uri $definitionSecurityCenterCoverage -OutFile $HOME/rule.json
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCCoverage" -Policy $HOME/rule.json -ManagementGroupName "lz-management-group"
        New-AzPolicyAssignment -name "SLZ-SCCoverage" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
        Remove-Item -Path $HOME/rule.json
    }
    Write-Host "Checking policy for Azure Security Center Auto-provisioning agents" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCAutoProvisioning" })) {
        Write-Host "Enabling Azure Security Center auto-provisioning"
        Invoke-WebRequest -Uri $definitionSecurityCenterAutoProvisioning -OutFile $HOME/rule.json
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCAutoProvisioning" -Policy $HOME/rule.json -ManagementGroupName "lz-management-group"
        New-AzPolicyAssignment -name "SLZ-SCAutoProvisioning" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
        Remove-Item -Path $HOME/rule.json
    }

    #if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "Allowed locations"})){
    #        # Policy to force deployment in Europe doesn't exist
    #        $definition2 = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
    #        New-AzPolicyAssignment -name "Allowed locations" -PolicyDefinition $definition2 -PolicyParameter '{"listOfAllowedLocations":{"value":["northeurope","westeurope"]}}' -Scope $scope
    #}

    # Loop to create all "SLZ-...........DiagnosticToStorageAccount" policies
    Invoke-WebRequest -Uri "$definitionParametersv1URI" -OutFile $HOME/parameters.json
    Invoke-WebRequest -Uri "$definitionListv1URI" -OutFile $HOME/definitionList.txt
    $definitionList = @()

    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
        $policyName = "SLZ-" + $_.Split(',')[0] + "1"
        $policyVersion = $_.Split(',')[1]
        $policyLink = $_.Split(',')[2]

        Write-Host "Checking policy : $policyName" -ForegroundColor Yellow

        # Removes Role assignment and policy assignment from previous installation
#        if ($objectId = (Get-AzRoleAssignment -Scope $scope | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
#            Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
#        }
        if ($GetPolicyAssignment = Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like $policyName }) {
            # Quick cheat to keep the effect as defined by the customer
            # To be deleted once not in use anymore
            if (!($effect = $GetPolicyAssignment.Properties.Parameters.effect.value)) {
                $effect = "DeployIfNotExists"
            }
            Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
        }
        else {
            if ($GetPolicyInitiative = Get-AzPolicySetDefinition | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
                if ($tmp = $GetPolicyInitiative.Properties.PolicyDefinitions.Where( { $_.PolicyDefinitionId -Like "*$policyName" }, 'SkipUntil', 1)) {
                    $effect = $tmp.parameters.effect.value
                }
                else {
                    $effect = "DeployIfNotExists"
                }
            }
            else {
                $effect = "DeployIfNotExists"
            }
        }
        $param = @{ storageAccountId = @{value = $GetStorageAccount.Id }; region = @{value = $GetResourceGroup.Location }; effect = @{value = $effect } }

        $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName "lz-management-group" | Where-Object { $_.Name -Like $policyName }
        if ($policyDefinition) {
            if (!($policyDefinition.Properties.metadata.version -eq $policyVersion)) {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                $policyDefinition = Set-AzPolicyDefinition -Id $policyDefinition.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Updated policy: $policyName"
            }
        }
        else {
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
            Remove-Item -Path $HOME/$policyName.json
            Write-Host "Created policy: $policyName"
        }
        $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
    }
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName "lz-management-group" | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
        Set-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
    }
    else {
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name "SLZ-policyGroup1" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location  -Scope $scope
        New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    }
    Remove-Item -Path $HOME/parameters.json
    Remove-Item -Path $HOME/definitionList.txt

    # Loop to create all "SLZ-...........DiagnosticToLogAnalytics" policies if log analytics workspace exists
    if ($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        Invoke-WebRequest -Uri $definitionParametersv2URI -OutFile $HOME/parameters.json
        Invoke-WebRequest -Uri $definitionListv2URI -OutFile $HOME/definitionList.txt
        $definitionList = @()

        Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
            $policyName = "SLZ-" + $_.Split(',')[0] + "2"
            $policyVersion = $_.Split(',')[1]
            $policyLink = $_.Split(',')[2]
    
            Write-Host "Checking policy : $policyName" -ForegroundColor Yellow

            # Removes Role assignment and policy assignment from previous installation
#            if ($objectId = (Get-AzRoleAssignment | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
#                Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
#            }
            if ($GetPolicyAssignment = Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like $policyName }) {
                # Quick cheat to keep the effect as defined by the customer
                # To be deleted once not in use anymore
                if (!($effect = $GetPolicyAssignment.Properties.Parameters.effect.value)) {
                    $effect = "DeployIfNotExists"
                }
                Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
            }
            else {
                if ($GetPolicyInitiative = Get-AzPolicySetDefinition | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
                    if ($tmp = $GetPolicyInitiative.Properties.PolicyDefinitions.Where( { $_.PolicyDefinitionId -Like "*$policyName" }, 'SkipUntil', 1)) {
                        $effect = $tmp.parameters.effect.value
                    }
                    else {
                        $effect = "DeployIfNotExists"
                    }
                }
                else {
                    $effect = "DeployIfNotExists"
                }
            }
            $param = @{ workspaceId = @{value = $GetLogAnalyticsWorkspace.ResourceId }; region = @{value = $GetResourceGroup.Location }; effect = @{value = $effect } }


            $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName "lz-management-group" | Where-Object { $_.Name -Like $policyName }
            if ($policyDefinition) {
                if (!($policyDefinition.Properties.metadata.version -eq $policyVersion)) {
                    Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                    $metadata = '{"version":"' + $policyVersion + '"}'
                    $policyDefinition = Set-AzPolicyDefinition -Id $policyDefinition.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
                    Remove-Item -Path $HOME/$policyName.json
                    Write-Host "Updated : $policyName"
                }
            }
            else {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Created : $policyName"
            }
            $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
        }
        if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName "lz-management-group" | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
            Set-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        }
        else {
            $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name "SLZ-policyGroup2" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
        Remove-Item -Path $HOME/parameters.json
        Remove-Item -Path $HOME/definitionList.txt
    }

    # Loop to create all "SLZ-...........DiagnosticToEventHub" policies
    if ($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName) {
        $GetEventHubAuthorizationRuleId = Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey"
        Invoke-WebRequest -Uri $definitionParametersv3URI -OutFile $HOME/parameters.json
        Invoke-WebRequest -Uri $definitionListv3URI -OutFile $HOME/definitionList.txt
        $definitionList = @()

        Get-Content -Path $HOME/definitionList.txt | ForEAch-Object {
            $policyName = "SLZ-" + $_.Split(',')[0] + "3"
            $policyVersion = $_.Split(',')[1]
            $policyLink = $_.Split(',')[2]

            Write-Host "Checking policy : $policyName" -ForegroundColor Yellow

            # Removes Role assignment and policy assignment from previous installation
#            if ($objectId = (Get-AzRoleAssignment | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
#                Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
#            }
            if ($GetPolicyAssignment = Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like $policyName }) {
                # Quick cheat to keep the effect as defined by the customer
                # To be deleted once not in use anymore
                if (!($effect = $GetPolicyAssignment.Properties.Parameters.effect.value)) {
                    $effect = "DeployIfNotExists"
                }
                Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
            }
            else {
                if ($GetPolicyInitiative = Get-AzPolicySetDefinition | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
                    if ($tmp = $GetPolicyInitiative.Properties.PolicyDefinitions.Where( { $_.PolicyDefinitionId -Like "*$policyName" }, 'SkipUntil', 1)) {
                        $effect = $tmp.parameters.effect.value
                    }
                    else {
                        $effect = "DeployIfNotExists"
                    }
                }
                else {
                    $effect = "DeployIfNotExists"
                }
            }
            $param = @{ eventHubRuleId = @{value = $GetEventHubAuthorizationRuleId.Id }; region = @{value = $GetResourceGroup.Location }; effect = @{value = $effect }; eventHubName = @{value = "insights-operational-logs" } }


            $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName "lz-management-group" | Where-Object { $_.Name -Like $policyName }
            if ($policyDefinition) {
                if (!($policyDefinition.Properties.metadata.version -eq $policyVersion)) {
                    Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                    $metadata = '{"version":"' + $policyVersion + '"}'
                    $policyDefinition = Set-AzPolicyDefinition -Id $policyDefinition.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
                    Remove-Item -Path $HOME/$policyName.json
                    Write-Host "Updated : $policyName"
                }
            }
            else {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Created : $policyName"
            }
            $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
        }
        if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName "lz-management-group" | where-Object { $_.Name -Like "SLZ-policyGroup3" }) {
            Set-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        }
        else {
            $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName "lz-management-group" -Name "SLZ-policyGroup3" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
        Remove-Item -Path $HOME/parameters.json
        Remove-Item -Path $HOME/definitionList.txt
    }
}
Export-ModuleMember -Function setup-Policy
