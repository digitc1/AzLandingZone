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
    # TODO: change URIs in Invoke-WebRequest cmdlet
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
    # TODO: change URIs in Invoke-WebRequest cmdlet
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
    if($set = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq "SLZ-MsDefendercloud"}){
        $params = @{ effect = @{value = "[parameters('effect')]" }}
        $pol = $policies | ForEach-Object {@{policyDefinitionId=$_.PolicyDefinitionId; parameters=$params}}
        New-AzPolicySetDefinition -Id $set.ResourceId -PolicyDefinition ($pol | ConvertTo-Json -Depth 5) -Para
        Write-Verbose "Updated policy set definition for Microsoft Defender for Cloud"
    } else {
        $params = @{ effect = @{value = "[parameters('effect')]" }}
        $pol = $policies | ForEach-Object {@{policyDefinitionId=$_.PolicyDefinitionId; parameters=$params}}
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-MsDefenderCloud" -PolicyDefinition ($pol | ConvertTo-Json -Depth 5) -Parameter '{"effect": { "type": "string" }}'
        $parameters = @{effect = "DeployIfNotExists"}
        New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -IdentityType 'SystemAssigned' -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope -PolicyParameterObject $parameters | Out-Null
        Write-Verbose "Created policy set definition for Microsoft Defender for Cloud"
    }

    # Add assignment
}
Export-ModuleMember -Function Set-PolicyMsDefender
