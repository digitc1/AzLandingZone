Function Onboard-AzLandingZone {
    (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children | ForEach-Object {
        Set-AzContext -SubscriptionId $_.Name | Out-Null
        setup-Subscription
        setup-SubscriptionContacts
        setup-Lighthouse
    }
}
Export-ModuleMember -Function Onboard-AzLandingZone