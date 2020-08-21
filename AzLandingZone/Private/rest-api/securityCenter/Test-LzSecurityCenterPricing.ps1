function Test-LzSecurityCenterPricing {
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubscriptionId
    )
    Write-Host -ForegroundColor Green "[-] Found a subscription Id: $SubscriptionId"
    Set-AzContext -SubscriptionId $SubscriptionId
    $ascTier = Get-AzSecurityPricing
    if ($ascTier.PricingTier -contains "Standard") {
        Write-Host -ForegroundColor Green "[-] Your ASC is ready to be connected to Azure Sentinel"
        return $true
    }
    else {
        Write-Host -ForegroundColor Red "[!] Your ASC is not Standard tier. Please enable Standard tier first!"
    }
}
Export-ModuleMember -Function Test-LzSecurityCenterPricing