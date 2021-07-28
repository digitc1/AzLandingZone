Function setup-MonitoringAgent {
    param(
        [Parameter(Mandatory=$true)][string]$name,
        $managementGroup = "lz-management-group"
    )
    $ruleFileURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollectionRule.json"
    $dataCollectionAssociationDefinitionURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollectionRuleAssociation.json"
    $dataCollectionAssociationParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollectionRuleAssociation.parameters.json"

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running the policy script"
        return;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        return;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)) {
        Write-Host "No Management group found for Secure Landing Zone"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }

    if(!($dataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ-dataCollectionRule"})){
        Invoke-WebRequest -Uri $ruleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $dataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ-dataCollectionRule" -RuleFile $HOME/ruleFile.json
        Remove-Item -Path $HOME/ruleFile.json
    }

    if(!($GetPolicyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-Monitor" })){
        Invoke-WebRequest -Uri $dataCollectionAssociationDefinitionURI -OutFile $HOME/policyDefinition.json
        Invoke-WebRequest -Uri $dataCollectionAssociationParametersURI -OutFile $HOME/policyParameters.json
        $GetPolicyDefinition = New-AzPolicyDefinition -Name "SLZ-Monitor" -Policy $HOME/policyDefinition.json -Parameter $HOME/policyParameters.json -ManagementGroupName $GetManagementGroup.Name
        Remove-Item -Path $HOME/policyDefinition.json
        Remove-Item -Path $HOME/policyParameters.json
    }

    if(!($policyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-Monitor"})){
        $policyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-Monitor" -Location "westeurope" -region "westeurope" -workspaceId $GetLogAnalyticsWorkspace.ResourceId -dataCollectionRuleId $dataCollectionRule.Id -PolicyDefinition $GetPolicyDefinition
        Start-Sleep -Seconds 20
    }

    if(!(Get-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
    }
}
Export-ModuleMember -Function setup-MonitoringAgent