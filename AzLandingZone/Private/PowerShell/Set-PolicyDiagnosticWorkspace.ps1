Function Set-PolicyDiagnosticWorkspace {
    [cmdletbinding()]
    
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )
    
    $definitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/parameters2.json"

    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return;
    }
    if (!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)) {
        Write-Error "No log analytics workspace found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup -Expand)) {
        Write-Error "No Management group found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return;
    }
    $scope = ($GetManagementGroup).Id

    Write-Host -ForegroundColor Yellow "Checking policies for Azure Landing log analytics workspace"

    Invoke-WebRequest -Uri $definitionListURI -OutFile $HOME/definitionList.txt
    Invoke-WebRequest -Uri $definitionParametersURI -OutFile $HOME/parameters.json
    $definitionList = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    
    Get-Content -Path $HOME/definitionList.txt | ForEach-Object -Parallel{
        $policyName = "SLZ-" + $_.Split(',')[0] + "2"
        $policyVersion = $_.Split(',')[1]
        $policyLink = $_.Split(',')[2]
        $scope = $($using:scope)
        $GetManagementGroup = $($using:GetManagementGroup)
        $localList = $using:definitionList
        $GetLogAnalyticsWorkspace = $using:GetLogAnalyticsWorkspace

        #
        # Check if a previous role assignment exists and remive it
        #
#        Write-Host -ForegroundColor Yellow "Checking if previous role assignment exist for $policyName"
#        if($assignment = Get-AzRoleAssignment -Scope $scope | Where-Object {$_.DisplayName -eq $policyName}){
#            Remove-AzRoleAssignment -InputObject $assignment | Out-Null
#            Write-Host "Removed previous role assignment exist for $policyName"
#        }

        #
        # Check if a previous policy assignment exists and remive it
        #
#        Write-Host -ForegroundColor Yellow "Checking if previous policy assignment exist for $policyName"
#        if($assignment = Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -eq $policyName}){
#            Remove-AzPolicyAssignment -InputObject $assignment | Out-Null
#            Write-Host "Removed previous policy assignment exist for $policyName"
#        }

        #
        # Check if the policy definition exists and create it or update it
        #
        Write-Verbose "Checking if policy definition exist for $policyName"
        if($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq $policyName}){
            if ($policy.Properties.metadata.version -eq $policyVersion) {
                Write-Verbose "$policyName is up-to-date"
            } else {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
#                if($policy.Properties.Parameters.region){
#                    # Policy is still an old version that uses region parameter. To be deleted.
#                    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
#                        if($assignment = (Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-policyGroup2"})) {
#                            Remove-AzPolicyAssignment -InputObject $assignment
#                            Start-Sleep -Seconds 15
#                        }
#                        Remove-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -Force
#                    }
#                    Remove-AzPolicyDefinition -InputObject $policy -Force
#                    Start-Sleep -Seconds 15
#                    $policy = New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata
#                } else {         
                    $policy = Set-AzPolicyDefinition -Id $policy.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
#                }
                Remove-Item -Path $HOME/$policyName.json
                Write-Verbose "Updated policy: $policyName"
            }
        } else {
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            $policy = New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata
            Remove-Item -Path $HOME/$policyName.json
            Write-Verbose "Created policy: $policyName"
        }

        #
        # Check if the policy is already part of the initiative and get parameters
        #
#        $effect = "DeployIfNotExists"
#        if ($GetPolicyInitiative = Get-AzPolicySetDefinition | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
#            if ($tmp = $GetPolicyInitiative.Properties.PolicyDefinitions.Where( { $_.PolicyDefinitionId -Like "*$policyName" }, 'SkipUntil', 1)) {
#                $effect = $tmp.parameters.effect.value
#            }
#        }
        $param = @{ workspaceId = @{value = "[parameters('workspaceId')]" }; policyName = @{value = "[parameters('policyName')]" } }
        $localList.Add(@{policyDefinitionId = $policy.ResourceId; parameters = $param })
    }

    #
    # Checking if the policy set definition for AHUB exist and update it or create it
    #
    Write-Verbose "Checking policy set definition for Azure diagnostic settings for log analytics workspace"
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
#        if(!$policyInitiative.Properties.PolicyDefinitions.Parameters.region){
            $policyInitiative | Set-AzPolicySetDefinition -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
#        } else {
#            if($assignment = (Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-policyGroup2"})) {
#                Remove-AzPolicyAssignment -InputObject $assignment
#                Start-Sleep -Seconds 15
#            }
#            Remove-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -Force
#            $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
#            $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -IdentityType 'SystemAssigned' -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
#            Start-Sleep -Seconds 15
#            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
#        }
        Write-Verbose "Updated policy set definition for Azure diagnostic settings for log analytics workspace"
    }
    else {
#        if($assignment = (Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -Like "SLZ-policyGroup2"})) {
#            Remove-AzPolicyAssignment -InputObject $assignment
#            Start-Sleep -Seconds 15
#        }
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) -Parameter '{"policyName": { "type": "string" }, "workspaceId":{"type": "string"}}'
        $parameters = @{policyName = "setByPolicy"; workspaceId = $GetLogAnalyticsWorkspace.ResourceId}
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -IdentityType 'SystemAssigned' -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope -PolicyParameterObject $parameters
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        Write-Verbose "Created policy set definition for Azure diagnostic settings for log analytics workspace"
    }
    Remove-Item -Path $HOME/definitionList.txt
    Remove-Item -Path $HOME/parameters.json
}
Export-ModuleMember -Function Set-PolicyDiagnosticWorkspace
