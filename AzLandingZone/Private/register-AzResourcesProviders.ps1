Function register-AzResourcesProviders {
    Param(
		[string]$name = "lzslz",
		[Parameter(Mandatory = $true)][string]$subscriptionId
    )

    if(!($GetSubscription = Get-AzSubscription | Where-Object {$_.Id -Like "$subscriptionId"})){
        Write-Host "Provided subscription is invalid. Make sure to provide a valid subscription name."
        return
    }
    
    Register-LzInsightsProvider -subscriptionId $GetSubscription.Id
    Register-LzManagedServicesProvider -subscriptionId $GetSubscription.Id
    Register-LzPolicyInsightsProvider -subscriptionId $GetSubscription.Id
    Register-LzSecurityProvider -subscriptionId $GetSubscription.Id
}
Export-ModuleMember -Function register-AzResourcesProviders