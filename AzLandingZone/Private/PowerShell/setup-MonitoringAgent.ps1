Function setup-MonitoringAgent {
    param(
        [Parameter(Mandatory=$true)][string]$name,
        $managementGroup = "lz-management-group"
    )
    $WindowsRuleFileURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollectionRule_Windows.json"
    $LinuxRuleFileURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollectionRule_Linux.json"
    $WindowsDataCollectionAssociationDefinitionURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollection_Windows.json"
    $LinuxDataCollectionAssociationDefinitionURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/monitor/dataCollection_Linux.json"
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

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection rule for Windows"
    if(!($WindowsDataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ-dataCollectionRule-Windows"})){
        Invoke-WebRequest -Uri $WindowsRuleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $WindowsDataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ-dataCollectionRule-Windows" -RuleFile $HOME/ruleFile.json
        Write-Host "Created virtual machine data collection rule for Windows"
        Remove-Item -Path $HOME/ruleFile.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection rule for Linux"
    if(!($LinuxDataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ-dataCollectionRule-Linux"})){
        Invoke-WebRequest -Uri $LinuxRuleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $LinuxDataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ-dataCollectionRule-Linux" -RuleFile $HOME/ruleFile.json
        Write-Host "Created virtual machine data collection rule for Linux"
        Remove-Item -Path $HOME/ruleFile.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy for Windows"
    if(!($WindowsPolicyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-MonitorWin" })){
        Invoke-WebRequest -Uri $WindowsDataCollectionAssociationDefinitionURI -OutFile $HOME/definition.json
        Invoke-WebRequest -Uri $dataCollectionAssociationParametersURI -OutFile $HOME/parameters.json
        $WindowsPolicyDefinition = New-AzPolicyDefinition -Name "SLZ-Monitor" -Policy $HOME/definition.json -Parameter $HOME/parameters.json -ManagementGroupName $GetManagementGroup.Name
        Write-Host "Created virtual machine data collection policy"
        Remove-Item -Path $HOME/definition.json
        Remove-Item -Path $HOME/parameters.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy for Linux"
    if(!($LinuxPolicyDefinition = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-MonitorLinux" })){
        Invoke-WebRequest -Uri $LinuxDataCollectionAssociationDefinitionURI -OutFile $HOME/definition.json
        Invoke-WebRequest -Uri $dataCollectionAssociationParametersURI -OutFile $HOME/parameters.json
        $LinuxPolicyDefinition = New-AzPolicyDefinition -Name "SLZ-MonitorLinux" -Policy $HOME/definition.json -Parameter $HOME/parameters.json -ManagementGroupName $GetManagementGroup.Name
        Write-Host "Created virtual machine data collection policy"
        Remove-Item -Path $HOME/definition.json
        Remove-Item -Path $HOME/parameters.json
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy assignment for Windows"
    if(!($WindowsPolicyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-MonitorWin"})){
        $WindowsPolicyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-MonitorWin" -Location $GetResourceGroup.Location -region $GetResourceGroup.Location -workspaceId $GetLogAnalyticsWorkspace.ResourceId -dataCollectionRuleId $WindowsDataCollectionRule.Id -PolicyDefinition $WindowsPolicyDefinition -AssignIdentity
        Write-Host "Created virtual machine data collection policy assignment for Windows"
        Start-Sleep -s 20
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection policy assignment for Linux"
    if(!($LinuxPolicyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-MonitorLinux"})){
        $LinuxPolicyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-MonitorLinux" -Location $GetResourceGroup.Location -region $GetResourceGroup.Location -workspaceId $GetLogAnalyticsWorkspace.ResourceId -dataCollectionRuleId $LinuxDataCollectionRule.Id -PolicyDefinition $LinuxPolicyDefinition -AssignIdentity
        Write-Host "Created virtual machine data collection policy assignment for Windows"
        Start-Sleep -s 20
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection role assignment for Windows"
    if(!(Get-AzRoleAssignment -ObjectId $WindowsPolicyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $WindowsPolicyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
        Write-Host "Created virtual machine data collection role assignment for Windows"
    }

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection role assignment for Linux"
    if(!(Get-AzRoleAssignment -ObjectId $LinuxPolicyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $LinuxPolicyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
        Write-Host "Created virtual machine data collection role assignment for Linux"
    }
}
Export-ModuleMember -Function setup-MonitoringAgent
