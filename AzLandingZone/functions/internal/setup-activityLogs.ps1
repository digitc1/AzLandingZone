Function Set-ActivityLogs {
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
	$token = Get-AzAccessToken
	$bodyJson = $body | ConvertTo-Json -Depth 5
	Invoke-WebRequest -Uri $uri -Method Put -Headers $token -Body $bodyJson
}
Export-ModuleMember -Function Set-ActivityLogs