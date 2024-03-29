Function Set-LzActiveDirectoryDiagnosticSettings {
	Param(
		[string]$name = "lzslz"
	)

	Write-Host -ForegroundColor Yellow "Configuring active directory diagnostic settings"

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Error "No Resource Group for Secure Landing Zone found"
		Write-Error "Please run setup script before running this script"
		return 1;
	}
	if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "*$name*"})){
		Write-Error "No Storage Account found for Secure Landing Zone"
		Write-Error "Please run setup script before running this script"
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
					'category' = 'SignInLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'AuditLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'NonInteractiveUserSignInLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'ServicePrincipalSignInLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'ManagedIdentitySignInLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'ProvisioningLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'ADFSSignInLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'RiskyUsers';
					'enabled' = 'true'
				}
				@{
					'category' = 'UserRiskEvents';
					'enabled' = 'true'
				}
				@{
					'category' = 'NetworkAccessTrafficLogs';
					'enabled' = 'true'
				}
				@{
					'category' = 'RiskyServicePrincipals';
					'enabled' = 'true'
				}
				@{
					'category' = 'ServicePrincipalRiskEvents';
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
	
	$uri = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/" + $logProfileName + "?api-version=2017-04-01"

	try{
		Write-Verbose "Configuring active directory diagnostic settings"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Verbose "Configured active directory diagnostic settings"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			default {Write-Error "An unexpected error happened. Contact Landing Zone FMB for additional support."}
		}
	}
}
Export-ModuleMember -Function Set-LzActiveDirectoryDiagnosticSettings