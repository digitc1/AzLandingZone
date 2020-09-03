Function Disconnect-LzSecurityCenter{
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

	$uri = "https://management.azure.com" + $GetWorkspace.ResourceId + "/providers/Microsoft.SecurityInsights/dataConnectors/" + $subscriptionId + "?api-version=2020-01-01"

	try{
		Write-Host -ForegroundColor Yellow "Disconnecting ASC to Azure Sentinel"
		$auth = Get-LzAccessToken
		Invoke-webrequest -Uri $uri -Method Delete -Headers $auth
		Write-Host "Disconnected ASC to Azure Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Connection does not exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function disconnect-LzSecurityCenter