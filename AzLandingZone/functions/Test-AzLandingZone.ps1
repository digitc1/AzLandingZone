Function Test-AzLandingZone {
    $username = [Environment]::Username
    $user = Get-AzAdUser | Where-Object {$_.DisplayName -Like "$username"}

    if($user.Count -ne 1){
        Write-Host "Impossible to identify the current user. Make sure the display name of your user is unique."
    }
    if(!($subscription = Get-AzSubscription | Where-Object {$_.Name -Like "SecLog*"})){
        Write-Host "Cannot find SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
    }
    $GetAzRoleAssignment = Get-AzRoleAssignment -scope "/subscriptions/$subscription.Id" -objectId $user.Id | Where-Object {$_.RoleDefinitionName -Like "Contributor" -Or $_.RoleDefinitionName -Like "Owner"}
    if($GetAzRoleAssignment.Count -eq 0) {
        Write-Host "Cannot find role assignment for SecLog subscription. Make sure you're owner or contributor of SecLog subscription."
    }
    
    Write-Host "Validation successful"
}
Export-ModuleMember -Function Test-AzLandingZone