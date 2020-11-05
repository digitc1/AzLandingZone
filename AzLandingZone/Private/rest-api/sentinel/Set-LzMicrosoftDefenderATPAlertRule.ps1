Function Set-LzMicrosoftDefenderATPAlertRule {
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
			'productFilter' = 'Microsoft Defender Advanced Threat Protection'
			'displayName' = 'Create incidents based on Microsoft Defender Advanced Threat Protection alerts'
			'enabled' = 'true'
			'description' = 'Create incidents based on all alerts generated in Microsoft Defender Advanced Threat Protection'
			'alertRuleTemplateName' = '327cd4ed-ca42-454b-887c-54e1c91363c6'
		}
	}
	$uri = "https://management.azure.com" + $GetLogAnalyticsWorkspace.ResourceId  + "/providers/Microsoft.SecurityInsights/alertRules/327cd4ed-ca42-454b-887c-54e1c91363c6?api-version=2020-01-01"

	try {
		Write-Host -ForegroundColor Green "Enabling alerts creation for Microsoft Defender Advanced Threat Protection in Sentinel"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host -ForegroundColor Green "Enabled alerts creation for Microsoft Defender Advanced Threat Protection in Sentinel"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Alerts creation for Microsoft Defender Advanced Threat Protection in Sentinel already enabled" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Set-LzMicrosoftDefenderATPAlertRule