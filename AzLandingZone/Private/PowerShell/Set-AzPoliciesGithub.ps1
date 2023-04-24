Function setup-PolicyGithub {
    [cmdletbinding()]

    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )

    Write-Host -ForegroundColor Yellow "Checking Azure Landing Zone policies configuration"
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Error "No Resource Group for Secure Landing Zone found"
        return;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup)){
        Write-Error "No Management Group for Secure Landing Zone found"
        return;
    }

    Write-Verbose "Checking user assigned identity"
    if(!($policyIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $GetResourceGroup.ResourceGroupName | where-Object {$_.Name -Like "$name-identity"})){
        $policyIdentity = New-AzUserAssignedIdentity -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name "$name-identity" -Location $GetResourceGroup.Location
        Write-Verbose "Created user assigned identity"
    }

    Write-Verbose "Checking user assigned identity role assignment"
    if(!(Get-AzRoleAssignment -RoleDefinitionName "Contributor" -Scope $GetManagementGroup.Id -objectId $policyIdentity.principalId)){
        New-AzRoleAssignment -RoleDefinitionName "Contributor" -Scope $GetManagementGroup.Id -ObjectId $policyIdentity.PrincipalId | out-Null
        Write-Verbose "Created role assignment 'Contributor'"
    }
    if(!(Get-AzRoleAssignment -RoleDefinitionName "Security Admin" -Scope $GetManagementGroup.Id -objectId $policyIdentity.principalId)){
        New-AzRoleAssignment -RoleDefinitionName "Security Admin" -Scope $GetManagementGroup.Id -ObjectId $policyIdentity.PrincipalId | out-Null
        Write-Verbose "Created role assignment 'Security Admin'"
    }

    Write-Host "$($Identity.Id)"

    if(!(Get-AzRoleAssignment -RoleDefinitionName "Resource Policy Contributor" -Scope $GetManagementGroup.Id -objectId $deploymentIdentity.Id)){
        New-AzRoleAssignment -RoleDefinitionName "Resource Policy Contributor" -Scope $GetManagementGroup.Id -ObjectId $deploymentIdentity.Id
        Write-Verbose "Created role assignment for github deployment"
    }    
}
Export-ModuleMember -Function setup-PolicyGithub
