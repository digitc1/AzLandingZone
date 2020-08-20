Function Register-LzPolicyInsightsProvider {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
	)

	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.policyInsights/register?api-version=2019-09-01"

	try {
		Write-Host -ForegroundColor Green "Registering Microsoft.policyInsights resource provider"
		$auth = Get-AzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Post -Headers $auth
		Write-Host -ForegroundColor Green "Registered Microsoft.policyInsights resource provider"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Microsoft.policyInsights resource provider already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Register-LzPolicyInsightsProvider