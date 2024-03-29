Function Set-LzSecurityAutoProvisioningSettings {
	Param (
		[Parameter(Mandatory=$true)][string]$subscriptionId,
		[ValidateSet("On", "Off")][string] $status = "On"
	)

	if(!(Get-AzSubscription -SubscriptionId $SubscriptionId)){
		Write-Host -ForegroundColor Red "Could not find subscription linked to provided subscriptionId"
		return 1;
	}

	$body = @{
		'properties' = @{
			'autoProvision' = $status
		}
	}
	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/Microsoft.Security/autoProvisioningSettings/default?api-version=2019-01-01"

	try {
		Write-Host -ForegroundColor Yellow "Configuring Azure security center agents auto-provisioning"
		$auth = Get-LzAccessToken
		Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
		Write-Host "Configured Azure security center agents auto-provisioning"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Azure security center agents auto-provisioning already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityAutoProvisioningSettings