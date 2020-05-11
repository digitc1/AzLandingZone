Function setup-Policy {
    param(
            [Parameter(Mandatory=$true)][string]$name
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

    Install-Module -Name Az.Security -Force

    #
    # Create variables needed for this script
    #

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }
    if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "*$name*"})){
            Write-Host "No Storage Account found for Secure Landing Zone"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupName "lz-management-group" -Expand | Where-Object {$_.Name -Like "lz-management-group"})){
            Write-Host "No Management group found for Secure Landing Zone"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }
    $location = $GetResourceGroup.Location
    $scope = ($GetManagementGroup).Id

    #
    # Creating policy definition
    #
    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "ASC_Default"})){
            Write-Host "Enabling first monitoring in Azure Security Center" -ForegroundColor Yellow
            $Policy = Get-AzPolicySetDefinition | Where-Object {$_.Properties.displayName -EQ 'Enable Monitoring in Azure Security Center'}
            New-AzPolicyAssignment -Name "ASC_Default" -DisplayName "Azure Security Center - Default" -PolicySetDefinition $Policy -Scope $scope | Out-Null
    }

    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "ASC_CIS"})){
            Write-Host "Enabling second monitoring in Azure Security Center" -ForegroundColor Yellow
            $Policy = Get-AzPolicySetDefinition | Where-Object {$_.Properties.displayName -EQ '[Preview]: Audit CIS Microsoft Azure Foundations Benchmark 1.1.0 recommendations and deploy specific supporting VM Extensions'}
            New-AzPolicyAssignment -Name "ASC_CIS" -DisplayName "Azure Security Center - CIS Compliance" -PolicySetDefinition $Policy -Scope $scope -listOfRegionsWhereNetworkWatcherShouldBeEnabled $location | Out-Null
    }

    #if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "Allowed locations"})){
    #        # Policy to force deployment in Europe doesn't exist
    #        $definition2 = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
    #        New-AzPolicyAssignment -name "Allowed locations" -PolicyDefinition $definition2 -PolicyParameter '{"listOfAllowedLocations":{"value":["northeurope","westeurope"]}}' -Scope $scope
    #}

    # Loop to create all "SLZ-...........DiagnosticToStorageAccount" policies
    Invoke-WebRequest -Uri "$definitionParametersv1URI" -OutFile $HOME/parameters.json
    Invoke-WebRequest -Uri "$definitionListv1URI" -OutFile $HOME/definitionList.txt

    Get-Content -Path $HOME/definitionList.txt | ForEAch-Object -Parallel {
            $policyName = "SLZ-" + $_.Split(',')[0] + "1"
            $policyVersion = $_.Split(',')[1]
            $policyLink = $_.Split(',')[2]

            Write-Host "Checking policy : $policyName" -ForegroundColor Yellow

            $GetDefinition = Get-AzPolicyDefinition | Where-Object {$_.Name -Like $policyName}
            if($GetDefinition)
            {
                    if(!($GetDefinition.Properties.metadata.version -eq $policyVersion)){
                        if($objectId = (Get-AzRoleAssignment | where-Object {$_.DisplayName -Like $policyName}).ObjectId){
                                    Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
                            }
                            Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
                            Remove-AzPolicyDefinition -Name $policyName -Force | Out-Null
                            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                            $metadata = '{"version":"'+$policyVersion+'"}'
                            $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                            New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -storageAccountId $GetStorageAccount.Id | Out-Null
                            Remove-Item -Path $HOME/$policyName.json
                    }
            }
            else{
                    Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                    $metadata = '{"version":"'+$policyVersion+'"}'
                    $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                    New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -storageAccountId $GetStorageAccount.Id | Out-Null
                    Remove-Item -Path $HOME/$policyName.json
            }
    }
    Remove-Item -Path $HOME/parameters.json
    Remove-Item -Path $HOME/definitionList.txt

    # Loop to create all "SLZ-...........DiagnosticToLogAnalytics" policies if log analytics workspace exists
    #if($GetLogAnalyticsWorkspace = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
    #        Invoke-WebRequest -Uri $definitionParametersv2URI -OutFile $HOME/parameters.json
    #        Invoke-WebRequest -Uri $definitionListv2URI -OutFile $HOME/definitionList.txt
    #        
    #        Get-Content -Path $HOME/definitionList.txt | ForEAch-Object -Parallel {
    #        $policyName = "SLZ-" + $_.Split(',')[0] + "2"
    #        $policyVersion = $_.Split(',')[1]
    #        $policyLink = $_.Split(',')[2]
    #
    #        Write-Host "Checking policy : $policyName" -ForegroundColor Yellow
    #
    #        $GetDefinition = Get-AzPolicyDefinition | Where-Object {$_.Name -Like $policyName}
    #        if($GetDefinition)
    #        {
    #                if($GetDefinition.Properties.metadata.version -eq $policyVersion){
    #                        Write-Host "$policyName already exist and is up-to-date"
    #                }
    #                else{
    #                        Write-Host "$policyName requires update"
    #                        if($objectId = (Get-AzRoleAssignment | where-Object {$_.DisplayName -Like $policyName}).ObjectId){
    #                            Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    #                        }
    #                        Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
    #                        Remove-AzPolicyDefinition -Name $policyName -Force | Out-Null
    #                        Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
    #                        $metadata = '{"version":"'+$policyVersion+'"}'
    #                        $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
    #                        New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -workspaceId $GetLogAnalyticsWorkspace.ResourceId | Out-Null
    #                        Remove-Item -Path $HOME/$policyName.json
    #                        Write-Host "Updated : $policyName"
    #                }
    #        }
    #        else{
    #                Write-Host "Create the new policy"
    #                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
    #                $metadata = '{"version":"'+$policyVersion+'"}'
    #                $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
    #                New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -workspaceId $GetLogAnalyticsWorkspace.ResourceId | Out-Null
    #                Remove-Item -Path $HOME/$policyName.json
    #                Write-Host "Created : $policyName"
    #        }
    #    }
    #    Remove-Item -Path $HOME/parameters.json
    #    Remove-Item -Path $HOME/definitionList.txt
    #}

    # Loop to create all "SLZ-...........DiagnosticToEventHub" policies
    if($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName){
        $GetEventHubAuthorizationRuleId = Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey"
        Invoke-WebRequest -Uri $definitionParametersv3URI -OutFile $HOME/parameters.json
        Invoke-WebRequest -Uri $definitionListv3URI -OutFile $HOME/definitionList.txt
        
            Get-Content -Path $HOME/definitionList.txt | ForEAch-Object -Parallel {
            $policyName = "SLZ-" + $_.Split(',')[0] + "3"
            $policyVersion = $_.Split(',')[1]
            $policyLink = $_.Split(',')[2]

            Write-Host "Checking policy : $policyName" -ForegroundColor Yellow

            $GetDefinition = Get-AzPolicyDefinition | Where-Object {$_.Name -Like $policyName}
            if($GetDefinition)
            {
                    if(!($GetDefinition.Properties.metadata.version -eq $policyVersion)){
                        if($objectId = (Get-AzRoleAssignment | where-Object {$_.DisplayName -Like $policyName}).ObjectId){
                                    Remove-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
                            }
                            Remove-AzPolicyAssignment -Name $policyName -Scope $scope | Out-Null
                            Remove-AzPolicyDefinition -Name $policyName -Force | Out-Null
                            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                            $metadata = '{"version":"'+$policyVersion+'"}'
                            $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                            New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -eventHubRuleId $GetEventHubAuthorizationRuleId.Id | Out-Null
                            Remove-Item -Path $HOME/$policyName.json
                    }
            }
            else{
                    Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                    $metadata = '{"version":"'+$policyVersion+'"}'
                    $policyDefinition = New-AzPolicyDefinition -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata -ManagementGroupName "lz-management-group"
                    New-AzPolicyAssignment -name $policyName -PolicyDefinition $policyDefinition -Scope $scope -AssignIdentity -Location $location -region $location -eventHubRuleId $GetEventHubAuthorizationRuleId.Id | Out-Null
                    Remove-Item -Path $HOME/$policyName.json
            }
        }
        Remove-Item -Path $HOME/parameters.json
        Remove-Item -Path $HOME/definitionList.txt
    }

    Write-Host "Waiting for previous task to complete" -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    #create role assignment for all policies
    Write-Host "Create role assignment for created and updated policies" -ForegroundColor Yellow
    $GetPolicyAssignment = Get-AzPolicyAssignment | where-object {$_.Name -like "SLZ-*"}
    ForEach ($policyAssignment in $GetPolicyAssignment) {
        if(!(Get-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId)){
            New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
            Write-Host "Created role assignment for: "$policyAssignment.Name
        }
    }

    #
    # Check if the account is registered to use the Azure Security Center
    # If not, register
    #
    (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children | ForEach-Object {
            Set-AzContext -SubscriptionId $_.Name
            Install-Module -Name Az.Security -Force | Out-Null
            Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "SqlServers" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "AppServices" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "KubernetesService" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "SqlServerVirtualMachines" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "ContainerRegistry" -PricingTier "Standard" | Out-Null
            Set-AzSecurityPricing -Name "KeyVaults" -PricingTier "Standard" | Out-Null

            #
            # Set auto-provisionning for Azure Security Center agents
            #
            Write-Host "Checking that security center is enabled and auto-provisioning is working" -ForegroundColor Yellow
            if(!((Get-AzSecurityAutoProvisioningSetting -Name "default").AutoProvision -Like "On")){
                    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision
            }
    }
}
Export-ModuleMember -Function setup-Policy
