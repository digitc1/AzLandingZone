function New-ConnectorConfiguration {

    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SubscriptionId
    )
        $connnectorCfg = [PSCustomObject]@{
            name = $SubscriptionId
            etag = (New-Guid).Guid
            kind = "AzureSecurityCenter"
            properties = @{
                SubscriptionId = $SubscriptionId
                dataTypes = @{
                    alerts = @{
                        state = "Enabled"
                    }
                }
            }
        }
    return $connnectorCfg
}
Export-ModuleMember -Function New-ConnectorConfiguration