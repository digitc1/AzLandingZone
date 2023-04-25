Function setup-Policy {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group",
        [bool]$enableSentinel = $false
    )

    Write-Host -ForegroundColor Yellow "Checking Azure Landing Zone policies"

    #
    # External resource required
    #
    #$definitionSecurityCenterCoverage = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterCoverage.json"
    $definitionSecurityCenterAutoProvisioning = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/securityCenter/definition-securityCenterAutoProvisioning.json"
    $policySetDefinitionIds = @("1f3afdf9-d0c9-4c3d-847f-89da613e70a8", "1a5bb27d-173f-493e-9568-eb56638dde4d", "612b5213-9160-4969-8578-1518bd2a000c")
    
    #
    # Create variables needed for this script
    #
    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }
    if (!(Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object { $_.StorageAccountName -Like "*$name*" })) {
        Write-Error "No Storage Account found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup -Expand)) {
        Write-Error "No Management group found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }
    $location = $GetResourceGroup.Location
    $scope = ($GetManagementGroup).Id

    Write-Verbose "Checking Azure Landing Zone policy to block deployment outside of Europe"
    if(!(Get-AzPolicyAssignment | Where-Object {$_.Name -Like "Allowed locations"})){
        $definition = Get-AzPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c
        New-AzPolicyAssignment -name "Allowed locations" -PolicyDefinition $definition -PolicyParameter '{"listOfAllowedLocations":{"value":["northeurope","westeurope", "francecentral", "germanywestcentral"]}}' -Scope $scope | Out-Null
        Write-Verbose "Created Azure Landing Zone policy to block deployment outside of Europe"
    }

    #
    # Creating policy set definition
    #
    forEach($policySetDefinitionId in $policySetDefinitionIds){
        $policy = Get-AzPolicySetDefinition -Id "/providers/Microsoft.Authorization/policySetDefinitions/$policySetDefinitionId"
        Write-Verbose "Checking registration for '$($policy.Properties.DisplayName)'"
        if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Properties.PolicyDefinitionId -eq $policy.ResourceId})) {
            $rand = Get-Random -Minimum 10000000000 -Maximum 99999999999999
            New-AzPolicyAssignment -Name $rand -DisplayName $Policy.Properties.DisplayName -PolicySetDefinition $Policy -Scope $scope | Out-Null
            Write-Verbose "Enabled registration for '$($policy.Properties.DisplayName)'"
        }
    }


    
    Write-Host "Checking registration for Microsoft Defender for Endpoint" -ForegroundColor Yellow
    if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "SLZ-MDE" })) {
        Write-Host "Enabling registration for Microsoft Defender for Endpoint"
        $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ '[Preview]: Deploy Microsoft Defender for Endpoint agent' }
        $policyAssignment = New-AzPolicyAssignment -Name "SLZ-MDE" -DisplayName "[Preview]: Deploy Microsoft Defender for Endpoint agent" -PolicySetDefinition $Policy -Scope $scope -IdentityType 'SystemAssigned' -Location $location
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    }

    #Write-Host "Checking policy for Azure Security Center coverage" -ForegroundColor Yellow
    #if (!(Get-AzPolicyAssignment -Scope $scope | where-Object { $_.Name -Like "SLZ-SCCoverage" })) {
    #    Write-Host "Enabling Azure Security Center coverage"
    #    Invoke-WebRequest -Uri $definitionSecurityCenterCoverage -OutFile $HOME/rule.json
    #    $policyDefinition = New-AzPolicyDefinition -Name "SLZ-SCCoverage" -Policy $HOME/rule.json -ManagementGroupName $GetManagementGroup.Name
    #    $policyAssignment = New-AzPolicyAssignment -name "SLZ-SCCoverage" -PolicyDefinition $policyDefinition -Scope $scope -IdentityType 'SystemAssigned' -Location $location
    #    Remove-Item -Path $HOME/rule.json
    #    Start-Sleep -Seconds 15
    #    New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    #}
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
    # Create a policy initiative for Microsoft Defender for Cloud
    #
    Set-PolicyMsDefender -name $name -managementGroup $managementGroup

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
    if($enableSentinel){
        Set-PolicyDiagnosticWorkspace -name $name -managementGroup $managementGroup
    }

    #
    # Create a policy initiative for diagnostic settings to event hub
    #
    Set-PolicyDiagnosticEventHub -name $name -managementGroup $managementGroup
}
Export-ModuleMember -Function setup-Policy
