Function Set-LzSubscriptionDiagnosticSettings {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
	)
	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
			Write-Host "No Resource Group for Secure Landing Zone found"
			Write-Host "Please run setup script before running this script"
			return 1;
	}
	if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "*$name*"})){
			Write-Host "No Storage Account found for Secure Landing Zone"
			Write-Host "Please run setup script before running this script"
			return 1;
	}
	$GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName
	$GetEventHubNamespace = Get-AzEventHubNamespace -ResourceGroupName $GetResourceGroup.ResourceGroupName
	$logProfileName = "lzactivity"

	$body = @{
		'properties' = @{
			'storageAccountId' = $GetStorageAccount.Id
			'logs' = @(
				@{
					'category' = 'Administrative';
					'enabled' = 'true'
				}
				@{
					'category' = 'Security';
					'enabled' = 'true'
				}
				@{
					'category' = 'ServiceHealth';
					'enabled' = 'true'
				}
				@{
					'category' = 'Alert';
					'enabled' = 'true'
				}
				@{
					'category' = 'Recommendation';
					'enabled' = 'true'
				}
				@{
					'category' = 'Policy';
					'enabled' = 'true'
				}
				@{
					'category' = 'Autoscale';
					'enabled' = 'true'
				}
				@{
					'category' = 'ResourceHealth';
					'enabled' = 'true'
				}
			)
		}
	}
	if($GetLogAnalyticsWorkspace){
		$body.properties.workspaceId = $GetLogAnalyticsWorkspace.ResourceId
	}
	if($GetEventHubNamespace){
		$authorization = Get-AzEventHubAuthorizationRule -ResourceGroupName $GetResourceGroup.ResourceGroupName -Namespace $GetEventHubNamespace.Name -Name "landingZoneAccessKey"
		$body.properties.eventHubAuthorizationRuleId = $authorization.Id
		$body.properties.eventHubName = "insights-operational-logs"
	}

	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.insights/diagnosticSettings/" + $logProfileName + "?api-version=2017-05-01-preview"

	try {
		Write-Host -ForegroundColor Green "Configuring subscription diagnostic settings"
		$auth = Get-AzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Configured subscription diagnostic settings"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Diagnostic settings already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSubscriptionDiagnosticSettings