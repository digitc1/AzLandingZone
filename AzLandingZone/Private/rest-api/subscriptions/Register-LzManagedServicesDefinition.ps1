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

	$body = @{
		'properties' = @{
            'registrationDefinitionName' = 'landingZoneDelegation'
            'description' = 'Provides Management access to the Azure Security Center and Log analytics to DIGIT S'
            'managedByTenantId' = '3a8968a8-fbcf-4414-8b5c-77255f50f37b'
            'authorizations' = @(
				@{
					'principalId' = 'f40bf004-4ec1-4882-aab7-8dcc1d6803be';
					'roleDefinitionId' = '39bc4728-0917-49c7-9d2c-d95423bc2eb4'
                }
                @{
					'principalId' = '1c0a1bf1-da6c-4d9e-a834-be9516da1ca0';
					'roleDefinitionId' = '39bc4728-0917-49c7-9d2c-d95423bc2eb4'
                }
                @{
					'principalId' = 'f40bf004-4ec1-4882-aab7-8dcc1d6803be';
					'roleDefinitionId' = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
                }
                @{
					'principalId' = '1c0a1bf1-da6c-4d9e-a834-be9516da1ca0';
					'roleDefinitionId' = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
                }
                @{
					'principalId' = 'f40bf004-4ec1-4882-aab7-8dcc1d6803be';
					'roleDefinitionId' = '73c42c96-874c-492b-b04d-ab87d138a893'
                }
                @{
					'principalId' = '1c0a1bf1-da6c-4d9e-a834-be9516da1ca0';
					'roleDefinitionId' = '73c42c96-874c-492b-b04d-ab87d138a893'
				}
				
			)
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