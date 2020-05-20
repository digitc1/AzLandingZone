Function Test-AzLandingZone {
    [cmdletbinding()]
    Param()

    $username = ([Environment]::Username).Replace("_",".")
    $user = Get-AzAdUser | Where-Object {$_.UserPrincipalName -Like "$username*"}

    if($user.Count -ne 1){
        Write-Verbose -Message "Impossible to identify the current user. Make sure the display name of your user is unique."
        return 1
    }
    if(!($subscription = Get-AzSubscription | Where-Object {$_.Name -Like "SECLOG*"})){
        Write-Verbose -Message "Cannot find SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
        return 1
    }
    if(!((Get-AzContext).Subscription.Name -Like "SECLOG*")){
        Write-Verbose -Message "Context is not set to SecLog subscription. Landing Zone resources will be deployed to the current context."
        Write-Verbose -Message Get-AzContext.Subscription.Name
    }
    $GetAzRoleAssignment = Get-AzRoleAssignment -scope "/subscriptions/$subscription" | Where-Object {$_.ObjectId -Like $user.Id} | Where-Object {$_.RoleDefinitionName -Like "Contributor" -Or $_.RoleDefinitionName -Like "Owner"}
    if($GetAzRoleAssignment.Count -eq 0) {
        Write-Verbose -Message "Cannot find role assignment for SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
        return 1
    }
    
    Write-Verbose -Message "Validation successful"
    return 0
}
Export-ModuleMember -Function Test-AzLandingZone