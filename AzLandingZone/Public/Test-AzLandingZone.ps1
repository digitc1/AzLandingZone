Function Test-AzLandingZone {
    <#
        .SYNOPSIS
        Test if current user has sufficient rights to apply the Landing Zone
        .DESCRIPTION
        Test if current user has sufficient rights to apply the Landing Zone
        .EXAMPLE
        Test-AzLandingZone
    #>
    [cmdletbinding()]
    Param()

    $servicePrincipalId = az ad signed-in-user show --query objectId -o tsv

    if(!($GetSubscription = Get-AzSubscription | Where-Object {$_.Name -Like "SECLOG*"})){
        Write-Verbose -Message "Cannot find SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
    }
    if(!((Get-AzContext).Subscription.Name -Like "SECLOG*")){
        Write-Verbose -Message "Context is not set to SecLog subscription. Landing Zone resources will be deployed to the current context."
        Write-Verbose -Message Get-AzContext.Subscription.Name
    }
    $GetAzRoleAssignment = Get-AzRoleAssignment -scope ("/subscriptions/"+$GetSubscription.Id) | Where-Object {$_.RoleDefinitionName -Like "Contributor" -Or $_.RoleDefinitionName -Like "Owner"}
    if(!( $GetAzRoleAssignment | Where-Object {$_.Id -Like $servicePrincipalId} )){
        if(!( Get-AzAdGroup | Where-Object {$_.Id -In $GetAzRoleAssignment.ObjectId} | Where-Object {(Get-AzADGroupMember -ObjectId $_.Id).Id -Contains "7801d80f-7753-4ad2-bc21-977155a9a76c"} )){
            Write-Verbose -Message "Cannot find role assignment for current context. Make sure you're owner or contributor of the subscription."
        }
    }
    
    Write-Verbose -Message "Validation successful"
    return 0
}
Export-ModuleMember -Function Test-AzLandingZone