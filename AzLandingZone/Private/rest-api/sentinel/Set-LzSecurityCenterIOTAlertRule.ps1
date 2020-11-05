Function Set-LzSecurityCenterAlertIotRule {
	Param (
		[String] $name = "lzslz"
	)

	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
		Write-Host "No Resource Group for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}
	if(!($GetLogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $GetResourceGroup.ResourceGroupName)){
		Write-Host "No Log analytics workspace for Secure Landing Zone found"
		Write-Host "Please run setup script before running this script"
		return 1;
	}

	$body = @{
		'etag'       = ''
		'kind'       = 'MicrosoftSecurityIncidentCreation'
		'properties' = @{
			'productFilter' = 'Azure Security Center for IoT'
			'displayName' = 'Create incidents based on Azure Security Center for IoT alerts'
			'enabled' = 'true'
			'description' = 'Create incidents based on all alerts generated in Azure Security Center for IoT'
			'alertRuleTemplateName' = 'a2e0eb51-1f11-461a-999b-cd0ebe5c7a72'
		}
	}
	$uri = "https://management.azure.com" + $GetLogAnalyticsWorkspace.ResourceId  + "/providers/Microsoft.SecurityInsights/alertRules/a2e0eb51-1f11-461a-999b-cd0ebe5c7a72?api-version=2020-01-01"

	try {
		Write-Host -ForegroundColor Green "Enabling alerts creation for Azure Security Center for IoT in Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Enabled alerts creation for Azure Security Center for IoT in Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Alerts creation for Azure Security Center in Sentinel already enabled" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzSecurityCenterIotAlertRule