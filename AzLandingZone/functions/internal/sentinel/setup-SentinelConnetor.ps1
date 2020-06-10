function setup-SentinelConnector {
    Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceRg,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId
)
    
    $workspaceId = (Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $WorkspaceRg).ResourceId
    if (!$workspaceId) {
        Write-Host -ForegroundColor Red "[!] Workspace cannot be found. Please try again"
    }
    else {
        Write-Host -ForegroundColor Green "[-] Your Azure Sentinel is connected to workspace: $WorkspaceName"
    }

    if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
        Write-Host -ForegroundColor Red "[!] Could not find subscription linked to provided subscriptionId"
        return $false
    }

    $status = Test-AzSecurityCenterTier -SubscriptionId $subscriptionId
    $authHeader = Get-AzAccessToken
    $connectorName = $subscriptionId
    if ($status -eq $true) {
        Write-Host -ForegroundColor Green "[-] Connecting ASC to Azure Sentinel is going to be started"
        $requestBody = New-ConnectorConfiguration -SubscriptionId $subscriptionId | ConvertTo-Json -Depth 4
        $uri = "https://management.azure.com" + $workspaceId + "/providers/Microsoft.SecurityInsights/dataConnectors/" + $connectorName + "?api-version=2019-01-01-preview"
        $response = Invoke-WebRequest -Uri $uri -Method Put -Headers $authHeader -Body $requestBody
        if ($response.StatusCode -eq "200") {
            Write-Host -ForegroundColor Yellow "[-] Succesfully connected ASC in subscription: $subscriptionId to Azure Sentinel"
        }
        else {
            Write-Host -ForegroundColor Red "[!] Failed to connect to Azure Sentinel"
        }
    }
}
Export-ModuleMember -Function setup-SentinelConnector