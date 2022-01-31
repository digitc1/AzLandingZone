Function Set-PolicyDiagnosticWorkspace {
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )
    
    $definitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList2.txt"
    $definitionParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/parameters2.json"

    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running the policy script"
        return;
    }
    if (!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)) {
        Write-Host "No log analytics workspace found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)) {
        Write-Host "No Management group found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return;
    }
    $scope = ($GetManagementGroup).Id

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
        Write-Host -ForegroundColor Yellow "Checking if previous role assignment exist for $policyName"
        if($assignment = Get-AzRoleAssignment -Scope $scope | Where-Object {$_.DisplayName -eq $policyName}){
            Remove-AzRoleAssignment -InputObject $assignment | Out-Null
            Write-Host "Removed previous role assignment exist for $policyName"
        }

        #
        # Check if a previous policy assignment exists and remive it
        #
        Write-Host -ForegroundColor Yellow "Checking if previous policy assignment exist for $policyName"
        if($assignment = Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -eq $policyName}){
            Remove-AzPolicyAssignment -InputObject $assignment | Out-Null
            Write-Host "Removed previous policy assignment exist for $policyName"
        }

        #
        # Check if the policy definition exists and create it or update it
        #
        Write-Host -ForegroundColor Yellow "Checking if policy definition exist for $policyName"
        if($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq $policyName}){
            if ($policy.Properties.metadata.version -eq $policyVersion) {
                Write-Host "$policyName is up-to-date"
            } else {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                $policy = Set-AzPolicyDefinition -Id $policy.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
                Remove-Item -Path $HOME/$policyName.json
                Write-Host "Updated policy: $policyName"
            }
        } else {
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            $policy = New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/$policyName.json -Parameter $HOME/parameters.json -Metadata $metadata
            Remove-Item -Path $HOME/$policyName.json
            Write-Host "Created policy: $policyName"
        }

        #
        # Check if the policy is already part of the initiative and get parameters
        #
        $effect = "DeployIfNotExists"
        if ($GetPolicyInitiative = Get-AzPolicySetDefinition | where-Object { $_.Name -Like "SLZ-policyGroup1" }) {
            if ($tmp = $GetPolicyInitiative.Properties.PolicyDefinitions.Where( { $_.PolicyDefinitionId -Like "*$policyName" }, 'SkipUntil', 1)) {
                $effect = $tmp.parameters.effect.value
            }
        }
        $param = @{ workspaceId = @{value = $GetLogAnalyticsWorkspace.ResourceId }; effect = @{value = $effect } }

        $localList.Add(@{policyDefinitionId = $policy.ResourceId; parameters = $param })
    }

    #
    # Checking if the policy set definition for AHUB exist and update it or create it
    #
    Write-Host -ForegroundColor Yellow "Checking policy set definition for Azure diagnostic settings for log analytics workspace"
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup2" }) {
        Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host "Updated policy set definition for Azure diagnostic settings for log analytics workspace"
    }
    else {
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup2" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        Write-Host "Created policy set definition for Azure diagnostic settings for log analytics workspace"
    }
    Remove-Item -Path $HOME/definitionList.txt
    Remove-Item -Path $HOME/parameters.json
}
Export-ModuleMember -Function Set-PolicyDiagnosticWorkspace
