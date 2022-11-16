Function Register-LzManagedServicesDefinition {
	Param(
		[string]$name = "lzslz",
		[string]$subscriptionId
	)
	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
			Write-Host "No Resource Group for Secure Landing Zone found"
			Write-Host "Please run setup script before running this script"
			return 1;
	}

	# TODO this function should have a unit test - consider adding the Pester unit test framework

	function authorizations () {
		Param([string]$principalId)
		return @(
			@{
				'principalId' = $principalId;
				'roleDefinitionId' = '39bc4728-0917-49c7-9d2c-d95423bc2eb4' # Security Reader
			}
			@{
				'principalId' = $principalId;
				'roleDefinitionId' = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' # Reader - TODO this is too wide
			}
			@{
				'principalId' = $principalId;
				'roleDefinitionId' = '73c42c96-874c-492b-b04d-ab87d138a893' # Log Analytics Reader
			}
		)
	}
	if ($SOC -eq "DIGIT") {
		$description += 'DIGIT S'
		$tenantId = "3a8968a8-fbcf-4414-8b5c-77255f50f37b"
		$authorizations = (authorizations -principalId "f40bf004-4ec1-4882-aab7-8dcc1d6803be") + (authorizations -principalId "1c0a1bf1-da6c-4d9e-a834-be9516da1ca0")
	
	} else {
		$description = 'CERTEU'
		$tenantId = "63c369aa-1f8d-4f72-b38a-db2270dc7929"
		$authorizations = (authorizations -principalId "da495ab8-fd31-4ff8-845c-f52bd1558822")
	}
	$body = @{
		'properties' = @{
            'registrationDefinitionName' = 'landingZoneDelegation'
            'description' = 'Provides Management access to the Microsoft Defender for Cloud and Log analytics to ' + $description
            'managedByTenantId' = $tenantId
            'authorizations' = $authorizations 
        }
	}
	$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/providers/microsoft.ManagedServices/registrationDefinitions/097ce9c3-516a-4829-86ad-4d04e4f6dd1e?api-version=2019-06-01"

	try {
		Write-Host -ForegroundColor Yellow "Creating delegated access definition"
		$auth = Get-LzAccessToken
		$requestResult = Invoke-webrequest -Uri $uri -Method Put -Headers $auth -Body ($body | ConvertTo-Json -Depth 5)
		Write-Host "Created delegated access definition"
	}
	catch {
		Switch ($_.Exception.Response.StatusCode.value__)
		{
			409 {Write-Host "Delegated access definition already configured" -ForegroundColor Yellow}
			default {Write-Host "An unexpected error happened. Contact Landing Zone FMB for additional support." -ForegroundColor Red}
		}
	}
}
Export-ModuleMember -Function Register-LzManagedServicesDefinition