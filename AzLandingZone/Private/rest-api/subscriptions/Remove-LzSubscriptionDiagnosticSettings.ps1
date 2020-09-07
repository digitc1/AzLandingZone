Function Remove-LzSubscriptionDiagnosticSettings {
	Param(
		[string]$subscriptionId
	)
	if(!(Get-AzSubscription -subscriptionId $subscriptionId)){
			Write-Host "Subscription not found"
			return;
	}
	$logProfileName = "lzactivity"

	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.insights/diagnosticSettings/" + $logProfileName + "?api-version=2017-05-01-preview"

	try {
		Write-Host -ForegroundColor Yellow "Removing subscription diagnostic settings"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Delete -Headers $auth
		Write-Host "Removed subscription diagnostic settings"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Diagnostic settings does not exist" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Remove-LzSubscriptionDiagnosticSettings