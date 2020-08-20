Function Register-LzSecurityProvider {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
	)

	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.security/register?api-version=2019-09-01"

	try {
		Write-Host -ForegroundColor Green "Registering Microsoft.security resource provider"
		$auth = Get-AzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Post -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Registered Microsoft.security resource provider"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Microsoft.security resource provider already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Register-LzSecurityProvider