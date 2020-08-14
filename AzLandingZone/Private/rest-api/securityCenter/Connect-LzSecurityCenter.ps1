Function Connect-LzSecurityCenter{
	Param(
		[string]$name = "lzslz",
		[Parameter(Mandatory=$true)][string]$subscriptionId
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
	if(!($GetWorkspace = Get-AzOperationalInsightsWorkspace -resourceGroupName $GetResourceGroup.ResourceGroupName | where-Object {$_.Name -Like "*$name*"})){
		Write-Host -ForegroundColor Red "Workspace cannot be found"
		return 1;
	}
	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = [PSCustomObject]@{
		'name' = $SubscriptionId
		'kind' = 'AzureSecurityCenter'
		'properties' = @{
			'SubscriptionId' = $SubscriptionId
			'dataTypes' = @{
				'alerts' = @{
					'state' = 'Enabled'
				}
			}
		}
	}
	$uri = "https://management.azure.com" + $GetWorkspace.ResourceId + "/providers/Microsoft.SecurityInsights/dataConnectors/" + $subscriptionId + "?api-version=2020-01-01"

	try{
		Write-Host -ForegroundColor Green "Connecting ASC to Azure Sentinel"
		$auth = Get-LzAccessToken
		Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
		Write-Host -ForegroundColor Green "Connected ASC to Azure Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Connection already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Connect-LzSecurityCenter