Function Test-AzLandingZone {
    $username = ([Environment]::Username).Replace("_",".")
    $user = Get-AzAdUser | Where-Object {$_.UserPrincipalName -Like "$username*"}

    if($user.Count -ne 1){
        Write-Verbose "Impossible to identify the current user. Make sure the display name of your user is unique."
        return 1
    }
    if(!($subscription = Get-AzSubscription | Where-Object {$_.Name -Like "SecLog*"})){
        Write-Verbose "Cannot find SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
        return 1
    }
    $GetAzRoleAssignment = Get-AzRoleAssignment -scope "/subscriptions/$subscription.Id" -objectId $user.Id | Where-Object {$_.RoleDefinitionName -Like "Contributor" -Or $_.RoleDefinitionName -Like "Owner"}
    if($GetAzRoleAssignment.Count -eq 0) {
        Write-Verbose "Cannot find role assignment for SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
        return 1
    }
    
    Write-Verbose "Validation successful"
    return 0
}
Export-ModuleMember -Function Test-AzLandingZone