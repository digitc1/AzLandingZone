Function setup-MonitoringAgent {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)][string]$name,
        $managementGroup = "lz-management-group"
    )
    $WindowsRuleFileURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/develop/definitions/monitor/dataCollectionRule_Windows.json"
    $LinuxRuleFileURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/develop/definitions/monitor/dataCollectionRule_Linux.json"

    Write-Host -ForegroundColor Yellow "Checking virtual machine data collection rule for Windows"

    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return;
    }
    if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
        return;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupName $managementGroup -Expand)) {
        Write-Error "No Management group found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }

    Write-Verbose "Checking virtual machine data collection rule for Windows"
    if(!($WindowsDataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ_dataCollectionRule_Windows"})){
        Invoke-WebRequest -Uri $WindowsRuleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $WindowsDataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ_dataCollectionRule_Windows" -RuleFile $HOME/ruleFile.json
        Write-Verbose "Created virtual machine data collection rule for Windows"
        Remove-Item -Path $HOME/ruleFile.json
    }

    Write-Verbose "Checking virtual machine data collection rule for Linux"
    if(!($LinuxDataCollectionRule = Get-AzDataCollectionRule | Where-Object {$_.Name -Like "SLZ_dataCollectionRule_Linux"})){
        Invoke-WebRequest -Uri $LinuxRuleFileURI -OutFile $HOME/ruleFile.json
        ((Get-Content -path $HOME/ruleFile.json -Raw) -replace '<workspaceId>',$GetLogAnalyticsWorkspace.ResourceId) | Set-Content -Path $HOME/ruleFile.json
        $LinuxDataCollectionRule = New-AzDataCollectionRule -location $GetResourceGroup.location -ResourceGroupName $GetResourceGroup.ResourceGroupName -ruleName "SLZ_dataCollectionRule_Linux" -RuleFile $HOME/ruleFile.json
        Write-Verbose "Created virtual machine data collection rule for Linux"
        Remove-Item -Path $HOME/ruleFile.json
    }

    Write-Verbose "Checking virtual machine data collection policy assignment for Windows"
    if(!($WindowsPolicyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-MonitorWin"})){
        $definition = Get-AzPolicyDefinition -Id "/providers/Microsoft.Authorization/policyDefinitions/244efd75-0d92-453c-b9a3-7d73ca36ed52"
        $WindowsPolicyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-MonitorWin" -Location $GetResourceGroup.Location -dcrResourceId $WindowsDataCollectionRule.Id -PolicyDefinition $definition -IdentityType 'SystemAssigned'
        Write-Verbose "Created virtual machine data collection policy assignment for Windows"
        Start-Sleep -s 20
    }

    Write-Verbose "Checking virtual machine data collection policy assignment for Linux"
    if(!($LinuxPolicyAssignment = Get-AzPolicyAssignment -Scope $GetManagementGroup.Id | Where-Object {$_.Name -Like "SLZ-MonitorLinux"})){
        $definition = Get-AzPolicyDefinition -Id "/providers/Microsoft.Authorization/policyDefinitions/2ea82cdd-f2e8-4500-af75-67a2e084ca74"
        $LinuxPolicyAssignment = New-AzPolicyAssignment -Scope $GetManagementGroup.Id -Name "SLZ-MonitorLinux" -Location $GetResourceGroup.Location -dcrResourceId $LinuxDataCollectionRule.Id -PolicyDefinition $definition -IdentityType 'SystemAssigned'
        Write-Verbose "Created virtual machine data collection policy assignment for Windows"
        Start-Sleep -s 20
    }

    Write-Verbose "Checking virtual machine data collection role assignment for Windows"
    if(!(Get-AzRoleAssignment -ObjectId $WindowsPolicyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $WindowsPolicyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
        Write-Verbose "Created virtual machine data collection role assignment for Windows"
    }

    Write-Verbose "Checking virtual machine data collection role assignment for Linux"
    if(!(Get-AzRoleAssignment -ObjectId $LinuxPolicyAssignment.Identity.principalId -Scope ($GetManagementGroup).Id)){
        New-AzRoleAssignment -ObjectId $LinuxPolicyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope ($GetManagementGroup).Id | Out-Null
        Write-Verbose "Created virtual machine data collection role assignment for Linux"
    }
}
Export-ModuleMember -Function setup-MonitoringAgent
