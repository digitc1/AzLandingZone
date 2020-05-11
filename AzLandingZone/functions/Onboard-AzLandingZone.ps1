Function Onboard-AzLandingZone {
    $children = (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children
    Get-AzSubscription | ForEach-Object {
        if ($_.Name -notin $children.DisplayName){
            if($_.Name -Like "SecLog*"){
                New-AzManagementGroupSubscription -GroupName "lz-management-group" -SubscriptionId $_.Id
            }
            else{
                Write-Host "Do you want to onboard the following subscription: " $_.Name
                $param = read-Host "enter y or n (default No)"
                if($param -Like "y"){
                    Write-Host "Onboarding the subscription"
                    New-AzManagementGroupSubscription -GroupName "lz-management-group" -SubscriptionId $_.Id
                    Write-Host "The following subscription is now part of the Landing Zone: "$_.Name
                }
            }
        }
    }
    
    (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children | ForEach-Object {
        Set-AzContext -SubscriptionId $_.Name | Out-Null
        setup-Subscription
        setup-SubscriptionContacts
        setup-Lighthouse
    }
}
Export-ModuleMember -Function Onboard-AzLandingZone