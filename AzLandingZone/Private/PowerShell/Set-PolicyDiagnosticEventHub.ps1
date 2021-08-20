Function Set-PolicyDiagnosticEventHub {
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )
    
    $definitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/definitionList3.txt"
    $definitionParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/parameters3.json"

    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running the policy script"
        return;
    }
    if (!($GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName)) {
        Write-Host "No Storage Account found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)) {
        Write-Host "No Event Hub namespace found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return;
    }
    $scope = ($GetManagementGroup).Id
    $GetEventHubAuthorizationRuleId = Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey"

    Invoke-WebRequest -Uri $definitionListURI -OutFile $HOME/definitionList.txt
    Invoke-WebRequest -Uri $definitionParametersURI -OutFile $HOME/parameters.json
    $definitionList = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    
    Get-Content -Path $HOME/definitionList.txt | ForEach-Object -Parallel{
        $policyName = "SLZ-" + $_.Split(',')[0] + "3"
        $policyVersion = $_.Split(',')[1]
        $policyLink = $_.Split(',')[2]
        $scope = $($using:scope)
        $GetManagementGroup = $($using:GetManagementGroup)
        $localList = $using:definitionList
        $GetEventHubNamespace = $using:GetEventHubNamespace
        $GetEventHubAuthorizationRuleId = $using:GetEventHubAuthorizationRuleId

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
        $param = @{ eventHubRuleId = @{value = $GetEventHubAuthorizationRuleId.Id }; region = @{value = $GetStorageAccount.PrimaryLocation }; effect = @{value = $effect }; eventHubName = @{value = "insights-operational-logs" } }

        $localList.Add(@{policyDefinitionId = $policy.ResourceId; parameters = $param })
    }

    #
    # Checking if the policy set definition for AHUB exist and update it or create it
    #
    Write-Host -ForegroundColor Yellow "Checking policy set definition for Azure diagnostic settings for event hub"
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-policyGroup3" }) {
        Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host "Updated policy set definition for Azure diagnostic settings for event hub"
    }
    else {
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-policyGroup3" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        Write-Host "Created policy set definition for Azure diagnostic settings for event hub"
    }
    Remove-Item -Path $HOME/definitionList.txt
    Remove-Item -Path $HOME/parameters.json
}
Export-ModuleMember -Function Set-PolicyDiagnosticEventHub
