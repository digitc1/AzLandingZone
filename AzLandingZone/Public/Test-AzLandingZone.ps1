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
    .EXAMPLE
    Test-AzLandingZone -verbose
#>
    [cmdletbinding()]
    Param()

    # Get current user information
    $currentUser = Get-AzADUser -SignedIn
    Write-Verbose "Currently connected as '$($currentUser.DisplayName)'"

    # Get current subscription information
    if (!((Get-AzContext).Subscription.Name -Like "*SECLOG*")) {
        if (!(Get-AzSubscription | Where-Object { $_.Name -Like "*SECLOG*" })) {
            Write-Error -Message "Cannot find SECLOG subscription. Make sure the SECLOG subscription exists and you're owner of the subscription"
        }
        else {
            Write-Error -Message "Context is not set to SECLOG subscription."
            Write-Error -Message "Switch the context to SECLOG subscription using the following command:"
            Write-Error -Message 'Get-AzSubscription | Where-Object {$_.Name -like "*SECLOG*"} | Set-AzContext'
        }
        return
    }
    Write-Verbose "Found SECLOG subscription available in the context"

    # Get role information about role Assignment
    $scope = "/subscriptions/" + (Get-AzContext).Subscription.Id
    $GetRoleAssignment = Get-AzRoleAssignment -scope $scope | Where-Object { $_.RoleDefinitionName -eq "Owner" }
    if ($GetRoleAssignment | Where-Object { $_.objectId -eq $currentUser.Id }) {
        Write-Verbose -Message "Found direct Owner role assignment to the current user "
    }
    else {
        $recursiveGroupMembers = @()
        $recursiveGroupMembers += (Get-AzADGroup | Where-Object { $_.Id -In $GetRoleAssignment.objectId } | ForEach-Object -Process {
                $group = Get-AzADGroup -objectId $_.Id
                Write-Verbose "Checking members for group $($group.DisplayName)"
                get-recursivegroupmembers -groupId $_.Id
            })
        if ($currentUser.Id -In ($recursiveGroupMembers.Id | Get-Unique)) {
            Write-Verbose -Message "Found Owner role assigned via group for current user"
        }
        else {
            Write-Error -Message "Current user does not have Owner role on the current context"
            return
        }
    }
    Write-Verbose -Message "Script executed"
    Write-Host "Validation successful" -ForegroundColor "Green"
}
Export-ModuleMember -Function Test-AzLandingZone