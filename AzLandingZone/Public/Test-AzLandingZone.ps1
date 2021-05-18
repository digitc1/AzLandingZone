Function get-recursivegroupmembers {
    param(
        $groupId
    )
    $localNestedGroupMembers = @()
    $members = Get-AzADGroupMember -ObjectId $groupId
    foreach ($member in $members) {
        if ($member.ObjectType -eq "Group" ) {
            $localNestedGroupMembers += get-recursivegroupmembers -groupId $member.Id
        }
        else {
            $localNestedGroupMembers += $member
        }
    }
    return $localNestedGroupMembers
}

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

    # Get current user information
    $servicePrincipalId = az ad signed-in-user show --query objectId -o tsv
    $currentUser = Get-AzADUser | Where-Object { $_.Id -eq $servicePrincipalId }
    Write-Verbose "Currently connected as '$($currentUser.DisplayName)'"

    # Get current subscription information
    if (!((Get-AzContext).Subscription.Name -Like "*SECLOG*")) {
        if (!(Get-AzSubscription | Where-Object { $_.Name -Like "*SECLOG*" })) {
            Write-Verbose -Message "Cannot find SECLOG subscription. Make sure the SECLOG subscription exists and you're owner of the subscription"
        }
        else {
            Write-Verbose -Message "Context is not set to SECLOG subscription."
            Write-Verbose -Message "Switch the context to SECLOG subscription using the following command:"
            Write-Verbose -Message "Get-AzSubscription | Where-Object {$_.Name -like "*SECLOG*"} | Set-AzContext"
        }
    }

    # Get role information about role Assignment
    $scope = "/subscriptions/" + (Get-AzContext).Subscription.Id
    $GetRoleAssignment = Get-AzRoleAssignment -scope $scope | Where-Object { $_.RoleDefinitionName -eq "Owner" }
    if ($GetRoleAssignment | Where-Object { $_.objectId -eq $servicePrincipalId }) {
        Write-Verbose -Message "Owner role assigned to the user"
    }
    else {
        $recursiveGroupMembers = @()
        $recursiveGroupMembers += (Get-AzADGroup | Where-Object { $_.Id -In $GetRoleAssignment.objectId } | ForEach-Object -Process {
                $group = Get-AzADGroup -objectId $_.Id
                Write-Verbose "Checking members for group $($group.DisplayName)"
                get-recursivegroupmembers -groupId $_.Id
            })
        if ($servicePrincipalId -In ($recursiveGroupMembers.Id | Get-Unique)) {
            Write-Verbose -Message "Owner role assigned via to the group"
        }
        else {
            Write-Verbose -Message "Current user does not have owner right on the current context"
        }
    }
    Write-Verbose -Message "Script executed"
}
Export-ModuleMember -Function Test-AzLandingZone