Function Set-LzAzureATPAlertRule {
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
			'productFilter' = 'Azure Advanced Threat Protection'
			'displayName' = 'Create incidents based on Azure Advanced Threat Protection alerts'
			'enabled' = 'true'
			'description' = 'Create incidents based on all alerts generated in Azure Advanced Threat Protection'
			'alertRuleTemplateName' = '40ba9493-4183-4eee-974f-87fe39c8f267'
		}
	}
	$uri = "https://management.azure.com" + $GetLogAnalyticsWorkspace.ResourceId  + "/providers/Microsoft.SecurityInsights/alertRules/40ba9493-4183-4eee-974f-87fe39c8f267?api-version=2020-01-01"

	try {
		Write-Host -ForegroundColor Green "Enabling alerts creation for Azure Advanced Threat Protection in Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Enabled alerts creation for Azure Advanced Threat Protection in Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Alerts creation for Azure Advanced Threat Protection in Sentinel already enabled" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzAzureATPAlertRule