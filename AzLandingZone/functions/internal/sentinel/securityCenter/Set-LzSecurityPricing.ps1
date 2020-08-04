Function Set-LzSecurityPricing {
	Param (
		[Parameter(Mandatory=$true)][string]$subscriptionId
	)

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = @{
		'properties' = @{
			'pricingTier' = 'Standard'
		}
	}

	try {
		Write-Host -ForegroundColor Green "Configuring  Azure Security Center to standard tier"
		$auth = Get-AzAccessToken
		"virtualMachines", "SqlServers", "AppServices", "StorageAccounts", "SqlServerVirtualMachines", "KubernetesService", "ContainerRegistry", "KeyVaults" | ForEach-Object {
			$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/pricings/" + $_ + "?api-version=2018-06-01"
			$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		}
		Write-Host -ForegroundColor Green "Configured Azure Security Center to standard tier"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Auto-provisioning already exists" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityPricing