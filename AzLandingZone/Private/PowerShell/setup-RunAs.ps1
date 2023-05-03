Function setup-RunAs {
	[cmdletbinding()]
    param(
		[string]$name = "lzslz",
		[string]$managementGroup = "lz-management-group"
	)

	Write-Host -Foreground Yellow "Checking Azure Landing Zone automation service principal"
	
	#
    # Checking variables and requirements
    #
	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*" )){
		Write-Error "No Resource Group for the Secure Landing Zone found"
		return;
	}
	if(!($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.ResourceGroupName -like $GetResourceGroup.ResourceGroupName} )){
		Write-Error "No Automation account for Secure Landing Zone found"
		return;
	}
	if(!($GetManagementGroup = Get-AzManagementGroup -GroupId $managementGroup)){
		Write-Error "No management group for the secure Landing Zone found"
		return;
	}
	
	if(!($GetAutomationAccount.Identity)){
        	$GetAutomationAccount = Set-AzAutomationAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.AutomationAccountName -AssignSystemIdentity
    		Start-Sleep -Seconds 15
	}
	
	#
	# Checking role assignment for Azure automation account
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking role assignment for the automation account at the subscription level"
	if(!(Get-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" | Where-Object {$_.objectId -eq $GetAutomationAccount.Identity.PrincipalId})){
		New-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" -RoleDefinitionName "Contributor" -objectId $GetAutomationAccount.Identity.PrincipalId | Out-Null
		Write-Verbose "Created role assignment for the automation account at the subscription level"
	}
	Write-Verbose "Checking role assignment for the automation account at the management group level"
	if(!(Get-AzRoleAssignment -scope $GetManagementGroup.id | Where-Object {$_.objectId -eq $GetAutomationAccount.Identity.PrincipalId})){
		New-AzRoleAssignment -scope $GetManagementGroup.Id -RoleDefinitionName "Owner" -objectId $GetAutomationAccount.Identity.PrincipalId | Out-Null
		Write-Verbose "Created role assignment for the automation account at the management group level"
	}
}
Export-ModuleMember -Function setup-RunAs
