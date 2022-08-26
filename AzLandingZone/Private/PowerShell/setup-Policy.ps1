Function setup-Policy {
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )

    #
    # External resource required
    #
    $definitionSecurityCenterCoverage = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterCoverage.json"
    $definitionSecurityCenterAutoProvisioning = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterAutoProvisioning.json"

    #
    # Create variables needed for this script
    #
    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Please run setup script before running the policy script"
        return 1;
    }
    if (!(Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object { $_.StorageAccountName -Like "*$name*" })) {
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
    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "Allowed locations"})){
        $definition = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
        New-AzPolicyAssignment -name "Allowed locations" -PolicyDefinition $definition -PolicyParameter '{"listOfAllowedLocations":{"value":["northeurope","westeurope", "francecentral", "germanywestcentral"]}}' -Scope $scope | Out-Null
    }
    
    Write-Host "Checking registration for Azure Security Center CIS Benchmark" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "ASC_Default" })) {
        Write-Host "Enabling Azure Security Benchmark"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ 'Azure Security Benchmark' }
        New-AzPolicyAssignment -Name "ASC_Default" -DisplayName "Azure Security Benchmark" -PolicySetDefinition $Policy -Scope $scope | Out-Null
    }
    Write-Host "Checking registration for extended Azure Security Center CIS Benchmark 1.1.0" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "ASC_CIS" })) {
        Write-Host "Enabling second monitoring in Azure Security Center"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ 'CIS Microsoft Azure Foundations Benchmark v1.1.0' }
        New-AzPolicyAssignment -Name "ASC_CIS" -DisplayName "Azure Security Center - CIS Compliance" -PolicySetDefinition $Policy -Scope $scope -listOfRegionsWhereNetworkWatcherShouldBeEnabled $location | Out-Null
    }
    Write-Host "Checking registration for extended Azure Security Center CIS Benchmark 1.3.0" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "ASC_CIS_V3" })) {
        Write-Host "Enabling second monitoring in Azure Security Center"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ 'CIS Microsoft Azure Foundations Benchmark v1.3.0' }
        New-AzPolicyAssignment -Name "ASC_CIS_v3" -DisplayName "Azure Security Center - CIS Compliance - 1.3.0" -PolicySetDefinition $Policy -Scope $scope | Out-Null
    }
    Write-Host "Checking registration for Microsoft Defender for Endpoint" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "SLZ-MDE" })) {
        Write-Host "Enabling registration for Microsoft Defender for Endpoint"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ '[Preview]: Deploy Microsoft Defender for Endpoint agent' }
        $policyAssignment = New-AzPolicyAssignment -Name "SLZ-MDE" -DisplayName "[Preview]: Deploy Microsoft Defender for Endpoint agent" -PolicySetDefinition $Policy -Scope $scope -IdentityType 'SystemAssigned' -Location $location
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    }

    Write-Host "Checking policy for Azure Security Center coverage" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCCoverage" })) {
        Write-Host "Enabling Azure Security Center coverage"
        Invoke-WebRequest -Uri $definitionSecurityCenterCoverage -OutFile $HOME/rule.json
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCCoverage" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
        $policyAssignment = New-AzPolicyAssignment -name "SLZ-SCCoverage" -PolicyDefinition $policyDefinition -Scope $scope -IdentityType 'SystemAssigned' -Location $location
        Remove-Item -Path $HOME/rule.json
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    }
    Write-Host "Checking policy for Azure Security Center Auto-provisioning agents" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCAutoProvisioning" })) {
        Write-Host "Enabling Azure Security Center auto-provisioning"
        Invoke-WebRequest -Uri $definitionSecurityCenterAutoProvisioning -OutFile $HOME/rule.json
        $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCAutoProvisioning" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
        $policyAssignment = New-AzPolicyAssignment -name "SLZ-SCAutoProvisioning" -PolicyDefinition $policyDefinition -Scope $scope -IdentityType 'SystemAssigned' -Location $location
        Remove-Item -Path $HOME/rule.json
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    }

    #
    # Create a policy initiative for AHUB
    #
    Set-PolicyAHUB -name $name -managementGroup $managementGroup

    #
    # Create a policy initiative for diagnostic settings to storage account
    #
    Set-PolicyDiagnosticStorage -Name $name -managementGroup $managementGroup 

    #
    # Create a policy initiative for diagnostic settings to log analytics workspace
    #
    Set-PolicyDiagnosticWorkspace -name $name -managementGroup $managementGroup

    #
    # Create a policy initiative for diagnostic settings to event hub
    #
    Set-PolicyDiagnosticEventHub -name $name -managementGroup $managementGroup
}
Export-ModuleMember -Function setup-Policy
