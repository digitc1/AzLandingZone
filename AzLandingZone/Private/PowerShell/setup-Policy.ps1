Function setup-Policy {
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )

    #
    # External resource required
    #
    $definitionListv1URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList1.txt"
    $definitionParametersv1URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/parameters1.json"
    $definitionListv2URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionParametersv2URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/parameters2.json"
    $definitionListv3URI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList3.txt"
    $definitionParametersv3URI = "https://raw.githubusercontent.com/digitc1/AZLandingZonePublic/master/definitions/parameters3.json"
    $definitionSecurityCenterCoverage = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterCoverage.json"
    $definitionSecurityCenterAutoProvisioning = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterAutoProvisioning.json"
    $definitionAHUBWindowsServers = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/hybridBenefit/windowsServer.json"
    $definitionAHUBWindowsClients = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/hybridBenefit/windowsClient.json"
    $definitionAHUBSQLvm = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/hybridBenefit/sqlVirtualMachine.json"
    $definitionAHUBSQLdb = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/hybridBenefit/sqlDatabase.json"

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
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)) {
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
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "Azure Security Benchmark" })) {
        Write-Host "Enabling Azure Security Benchmark"
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
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCCoverage" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
        New-AzPolicyAssignment -name "SLZ-SCCoverage" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
        Remove-Item -Path $HOME/rule.json
    }
    Write-Host "Checking policy for Azure Security Center Auto-provisioning agents" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCAutoProvisioning" })) {
        Write-Host "Enabling Azure Security Center auto-provisioning"
        Invoke-WebRequest -Uri $definitionSecurityCenterAutoProvisioning -OutFile $HOME/rule.json
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCAutoProvisioning" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
        New-AzPolicyAssignment -name "SLZ-SCAutoProvisioning" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
        Remove-Item -Path $HOME/rule.json
    }

    # Checking registration for rules about Azure Hybrid Benefit
    Write-Host "Checking policy assignment for Azure Hybrid Benefit for Windows servers" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-AHUBWindowssrv" })) {
        Write-Host "Checking policy definition for Azure Hybrid Benefit for Windows servers" -ForegroundColor Yellow
        if(!($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like "SLZ-AHUBWindowssrv" })) {
            Invoke-WebRequest -Uri $definitionAHUBWindowsServers -OutFile $HOME/rule.json
            $policyDefinition = New-AzPolicyDefinition -Name "SLZ-AHUBWindowssrv" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
            Remove-Item -Path $HOME/rule.json
        }
        New-AzPolicyAssignment -name "SLZ-AHUBWindowssrv" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
    }
    Write-Host "Checking policy assignment for Azure Hybrid Benefit for Windows clients" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-AHUBWindows" })) {
        Write-Host "Checking policy definition for Azure Hybrid Benefit for Windows clients" -ForegroundColor Yellow
        if(!($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like "SLZ-AHUBWindows" })) {
            Invoke-WebRequest -Uri $definitionAHUBWindowsClients -OutFile $HOME/rule.json
            $policyDefinition = New-AzPolicyDefinition -Name "SLZ-AHUBWindows" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
            Remove-Item -Path $HOME/rule.json
        }
        New-AzPolicyAssignment -name "SLZ-AHUBWindows" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
    }
    Write-Host "Checking policy assignment for Azure Hybrid Benefit for SQL virtual machines" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-AHUBSQLvm" })) {
        Write-Host "Checking policy definition for Azure Hybrid Benefit for SQL virtual machines" -ForegroundColor Yellow
        if(!($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like "SLZ-AHUBSQLvm" })) {
            Invoke-WebRequest -Uri $definitionAHUBSQLvm -OutFile $HOME/rule.json
            $policyDefinition = New-AzPolicyDefinition -Name "SLZ-AHUBSQLvm" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
            Remove-Item -Path $HOME/rule.json
        }
        New-AzPolicyAssignment -name "SLZ-AHUBSQLvm" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
    }
    Write-Host "Checking policy assignment for Azure Hybrid Benefit for SQL databases" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-AHUBSQLdb" })) {
        Write-Host "Checking policy definition for Azure Hybrid Benefit for SQL databases" -ForegroundColor Yellow
        if(!($policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like "SLZ-AHUBSQLdb" })) {
            Invoke-WebRequest -Uri $definitionAHUBSQLdb -OutFile $HOME/rule.json
            $policyDefinition = New-AzPolicyDefinition -Name "SLZ-AHUBSQLdb" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
            Remove-Item -Path $HOME/rule.json
        }
        New-AzPolicyAssignment -name "SLZ-AHUBSQLdb" -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location | Out-Null
    }

    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "Allowed locations"})){
        $definition = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
        New-AzPolicyAssignment -name "Allowed locations" -PolicyDefinition $definition -PolicyParameter '{"listOfAllowedLocations":{"value":["northeurope","westeurope"]}}' -Scope $scope | Out-Null
    }

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
        if ($objectId = (Get-AzRoleAssignment -Scope $scope | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
            Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
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

        $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like $policyName }
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
            $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName $GetManagementGroup.Name
            Remove-Item -Path $HOME/$policyName.json
            Write-Host "Created policy: $policyName"
        }
        $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
    }
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
        Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
    }
    else {
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup1" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location  -Scope $scope
        Start-Sleep -Seconds 15
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
            if ($objectId = (Get-AzRoleAssignment | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
                Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
            }
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


            $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like $policyName }
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
                $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName $GetManagementGroup.Name
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Created : $policyName"
            }
            $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
        }
        if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
            Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        }
        else {
            $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
            Start-Sleep -Seconds 15
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
            if ($objectId = (Get-AzRoleAssignment | where-Object { $_.DisplayName -Like $policyName }).ObjectId) {
                Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
            }
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


            $policyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object { $_.Name -Like $policyName }
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
                $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName $GetManagementGroup.Name
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Created : $policyName"
            }
            $definitionList += @{policyDefinitionId = $policyDefinition.ResourceId; parameters = $param }
        }
        if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup3" }) {
            Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        }
        else {
            $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup3" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
            Start-Sleep -Seconds 15
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        }
        Remove-Item -Path $HOME/parameters.json
        Remove-Item -Path $HOME/definitionList.txt
    }
}
Export-ModuleMember -Function setup-Policy
