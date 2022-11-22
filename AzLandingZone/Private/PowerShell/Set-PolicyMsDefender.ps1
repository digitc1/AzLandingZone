Function Set-PolicyMsDefender {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )

    Write-Host -ForegroundColor Yellow "Checking Microsoft Defender for cloud policies"

    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup -Expand)) {
        Write-Error "No Management group found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return 1;
    }

    $MsDefenderPricingDefinitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/MSDefender/pricing/definitionList.txt"
    $MsDefenderDefinitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/MSDefender/definitionList.txt"
    $MsDefenderParametersURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/MSDefender/parameters.json"

    #
    # Creating policies for Azure Security Center pricing
    #
    # pricing section
    #
    Invoke-WebRequest -Uri $MsDefenderPricingDefinitionListURI -OutFile $HOME/definitionList.txt
    Invoke-WebRequest -Uri $MsDefenderParametersURI -OutFile $HOME/parameters.json
    $MDC_definition_list = Get-Content -Path $HOME/definitionList.txt
    forEach($line in $MDC_definition_list){
        $policyName = "SLZ-MDCpricing" + $line.Split(',')[0]
        $policyVersion = $line.Split(',')[1]
        $policyLink = $line.Split(',')[2]
        Write-Verbose "Checking policy '$policyName'"
        if(!($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq $policyName})){
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/definition.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/definition.json -Parameter $HOME/parameters.json -Metadata $metadata | Out-Null
            Remove-Item -Path $HOME/definition.json
            Write-Verbose "Created policy '$policyName'"
        } else {
            if($policy.Properties.Metadata.version -lt $policyVersion){
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/definition.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                Set-AzPolicyDefinition -Id $policy.ResourceId -Policy $HOME/definition.json -Metadata $metadata | Out-Null
                Remove-Item -Path $HOME/definition.json
                Write-Verbose "Updated policy '$policyName'"
            }
        }
    }
    Remove-Item -Path definitionList.txt
    Remove-Item -Path $HOME/parameters.json

    #
    # Creating policies for Azure Security Center
    #
    # non-pricing section
    #
    Invoke-WebRequest -Uri $MsDefenderDefinitionListURI -OutFile $HOME/definitionList.txt
    Invoke-WebRequest -Uri $MsDefenderParametersURI -OutFile $HOME/parameters.json
    $MDC_definition_list = Get-Content -Path $HOME/definitionList.txt
    forEach($line in $MDC_definition_list){
        $policyName = "SLZ-MDC" + $line.Split(',')[0]
        $policyVersion = $line.Split(',')[1]
        $policyLink = $line.Split(',')[2]
        Write-Verbose "Checking policy '$policyName'"
        if(!($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq $policyName})){
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/definition.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/definition.json -Parameter $HOME/parameters.json -Metadata $metadata | Out-Null
            Remove-Item -Path $HOME/definition.json
            Write-Verbose "Created policy '$policyName'"
        } else {
            if($policy.Properties.Metadata.version -lt $policyVersion){
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/definition.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                Set-AzPolicyDefinition -Id $policy.ResourceId -Policy $HOME/definition.json -Metadata $metadata | Out-Null
                Remove-Item -Path $HOME/definition.json
                Write-Verbose "Updated policy '$policyName'"
            }
        }
    }
    Remove-Item -Path definitionList.txt
    Remove-Item -Path $HOME/parameters.json
    
    Write-Verbose "Checking policy set definition for Microsoft Defender for Cloud"
    $policies = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -Like "SLZ-MDC*"}
    if($policySetDefinition = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq "SLZ-MsDefendercloud"}){
        $params = @{ effect = @{value = "[parameters('effect')]" }}
        $pol = $policies | ForEach-Object {@{policyDefinitionId=$_.PolicyDefinitionId; parameters=$params}}
        $policySetDefinition = Set-AzPolicySetDefinition -Id $policySetDefinition.ResourceId -PolicyDefinition ($pol | ConvertTo-Json -Depth 5)
        Write-Verbose "Updated policy set definition for Microsoft Defender for Cloud"
    } else {
        $params = @{ effect = @{value = "[parameters('effect')]" }}
        $pol = $policies | ForEach-Object {@{policyDefinitionId=$_.PolicyDefinitionId; parameters=$params}}
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-MsDefenderCloud" -PolicyDefinition ($pol | ConvertTo-Json -Depth 5) -Parameter '{"effect": { "type": "string" }}'
        Write-Verbose "Created policy set definition for Microsoft Defender for Cloud"
    }

    Write-Verbose "Checking policy set assignment for Microsoft Defender for Cloud"
    if(!($policySetAssignment = Get-AzPolicyAssignment -PolicyDefinitionId $policySetDefinition.ResourceId)){
        $parameters = @{effect = "DeployIfNotExists"}
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -IdentityType 'SystemAssigned' -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope -PolicyParameterObject $parameters
        Write-Verbose "Created policy set assignment for Microsoft Defender for Cloud"
    }

    $roles = @("Contributor", "Security Admin")
    forEach ($role in $roles){
        Write-Verbose "Checking role assignment '$role' for  Microsoft Defender for Cloud"
        if(!(Get-AzRoleAssignment -RoleDefinitionName $role -Scope $scope | Where-Object {$_.DisplayName -eq "SLZ-MsDefenderCloud"})){
            New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName $role -Scope $scope
            Write-Verbose "Created role assignment '$role' for  Microsoft Defender for Cloud"
        }
    }


    #
    # Policy for Azure container in MS Defender for Cloud
    #
    #Write-Host "Checking registration for 'Defender for Containers provisioning Policy extension for Arc-e'" -ForegroundColor Yellow
    #if (!(Get-AzPolicyAssignment -Scope $scope | Where-Object { $_.Name -Like "SLZ-MDE" })) {
    #    Write-Host "Enabling registration for Microsoft Defender for Endpoint"
    #    $Policy = Get-AzPolicySetDefinition | Where-Object { $_.Properties.displayName -EQ '[Preview]: Deploy Microsoft Defender for Endpoint agent' }
    #    $policyAssignment = New-AzPolicyAssignment -Name "SLZ-MDE" -DisplayName "[Preview]: Deploy Microsoft Defender for Endpoint agent" -PolicySetDefinition $Policy -Scope $scope -IdentityType 'SystemAssigned' -Location $location
    #    Start-Sleep -Seconds 15
    #    New-AzRoleAssignment -ObjectId $policyAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
    #}

    #/providers/Microsoft.Authorization/policyDefinitions/0adc5395-9169-4b9b-8687-af838d69410a
}
Export-ModuleMember -Function Set-PolicyMsDefender
