Function Set-PolicyAHUB {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )
    
    $definitionListURI = "https://raw.githubusercontent.com/digitc1/AzLandingZonePublic/master/definitions/hybridBenefit/definitionList.txt"

    if (!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")) {
        Write-Error "No Resource Group for Secure Landing Zone found"
        Write-Error "Please run setup script before running the policy script"
        return;
    }
    if (!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup -Expand)) {
        Write-Error "No Management group found for Secure Landing Zone"
        Write-Error "Please run setup script before running the policy script"
        return;
    }
    $scope = ($GetManagementGroup).Id

    Invoke-WebRequest -Uri $definitionListURI -OutFile $HOME/definitionList.txt
    $definitionList = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()
    
    Get-Content -Path $HOME/definitionList.txt | ForEach-Object -Parallel{
        $policyName = "SLZ-" + $_.Split(',')[0]
        $policyVersion = $_.Split(',')[1]
        $policyLink = $_.Split(',')[2]
        $scope = $($using:scope)
        $GetManagementGroup = $($using:GetManagementGroup)
        $localList = $using:definitionList

        #
        # Check if a previous role assignment exists and remive it
        #
        Write-Host -ForegroundColor Yellow "Checking if previous role assignment exist for $policyName"
        if($assignment = Get-AzRoleAssignment -Scope $scope | Where-Object {$_.DisplayName -eq $policyName}){
            Remove-AzRoleAssignment -InputObject $assignment | Out-Null
            Write-Verbose "Removed previous role assignment exist for $policyName"
        }

        #
        # Check if a previous policy assignment exists and remive it
        #
        Write-Host -ForegroundColor Yellow "Checking if previous policy assignment exist for $policyName"
        if($assignment = Get-AzPolicyAssignment -Scope $scope | Where-Object {$_.Name -eq $policyName}){
            Remove-AzPolicyAssignment -InputObject $assignment | Out-Null
            Write-Verbose "Removed previous policy assignment exist for $policyName"
        }

        #
        # Check if the policy Definition exists and create it or update it
        #
        Write-Host -ForegroundColor Yellow "Checking if policy definition exist for $policyName"
        if($policy = Get-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name | Where-Object {$_.Name -eq $policyName}){
            if ($policy.Properties.metadata.version -eq $policyVersion) {
                Write-Verbose "$policyName is up-to-date"
            } else {
                Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
                $metadata = '{"version":"' + $policyVersion + '"}'
                $policy = Set-AzPolicyDefinition -Id $policy.ResourceId -Policy $HOME/$policyName.json -Metadata $metadata
                Remove-Item -Path $HOME/$policyName.json
                Write-Verbose "Updated policy: $policyName"
            }
        } else {
            Invoke-WebRequest -Uri $policyLink -OutFile $HOME/$policyName.json
            $metadata = '{"version":"' + $policyVersion + '"}'
            $policy = New-AzPolicyDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyName -Policy $HOME/$policyName.json -Metadata $metadata
            Remove-Item -Path $HOME/$policyName.json
            Write-Verbose "Created policy: $policyName"
        }
        $localList.Add(@{policyDefinitionId = $policy.ResourceId})
    }

    #
    # Checking if the policy set definition for AHUB exist and update it or create it
    #
    Write-Host -ForegroundColor Yellow "Checking policy set definition for Azure AHUB"
    if ($policyInitiative = Get-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name | where-Object { $_.Name -Like "SLZ-AHUB" }) {
        Set-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name $policyInitiative.Name -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5) | Out-Null
        Write-Verbose "Updated policy set definition for Azure AHUB"
    }
    else {
        $policySetDefinition = New-AzPolicySetDefinition -ManagementGroupName $GetManagementGroup.Name -Name "SLZ-AHUB" -PolicyDefinition ($definitionList | ConvertTo-Json -Depth 5)
        $policySetAssignment = New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -AssignIdentity -Name $policySetDefinition.Name -location $GetResourceGroup.Location -Scope $scope
        Start-Sleep -Seconds 15
        New-AzRoleAssignment -ObjectId $policySetAssignment.Identity.principalId -RoleDefinitionName "Contributor" -Scope $scope | Out-Null
        Write-Verbose "Created policy set definition for Azure AHUB"
    }
    Remove-Item -Path $HOME/definitionList.txt
}
Export-ModuleMember -Function Set-PolicyAHUB
