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

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection rule"
    if(!($dataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ-dataCollectionRule"})){
        Invoke-WebRequest -Uri $ruleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $dataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ-dataCollectionRule" -RuleFile $HOME/ruleFile.json
        Write-Host "Created virtual machine data collection rule"
        Remove-Item -Path $HOME/ruleFile.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy"
    if(!($GetPolicyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-Monitor" })){
        Invoke-WebRequest -Uri $dataCollectionAssociationDefinitionURI -OutFile $HOME/policyDefinition.json
        Invoke-WebRequest -Uri $dataCollectionAssociationParametersURI -OutFile $HOME/policyParameters.json
        $GetPolicyDefinition = New-AzPolicyDefinition -Name "SLZ-Monitor" -Policy $HOME/policyDefinition.json -Parameter $HOME/policyParameters.json -ManagementGroupName $GetManagementGroup.Name
        Write-Host "Created virtual machine data collection policy"
        Remove-Item -Path $HOME/policyDefinition.json
        Remove-Item -Path $HOME/policyParameters.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy assignment"
    if(!($policyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-Monitor"})){
        $policyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-Monitor" -Location $GetResourceGroup.Location -region $GetResourceGroup.Location -workspaceId $GetLogAnalyticsWorkspace.ResourceId -dataCollectionRuleId $dataCollectionRule.Id -PolicyDefinition $GetPolicyDefinition -AssignIdentity
        Write-Host "Created virtual machine data collection policy assignment"
        Start-Sleep -s 20
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection role assignment"
    if(!(Get-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
        Write-Host "Created virtual machine data collection role assignment"
    }
}
Export-ModuleMember -Function setup-MonitoringAgent