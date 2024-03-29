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
	if(!($currentUser = Get-AzADUser -SignedIn)){
		Write-Error "Unable to identify the currently logged in user, skipping 'runAs account' creation"
		return;
	}
	
	#
    # Checking Azure key vault for Azure Landing Zone
    # If it doesn't exist, create it
    #
	Write-Verbose "Checking Azure Landing Zone key vault"
	if(!($GetKeyVault = Get-AzKeyVault | Where-Object {$_.ResourceGroupName -Like $GetResourceGroup.ResourceGroupName})){
		$rand = Get-Random -Minimum 1000000 -Maximum 9999999999
		$vaultName = "lzslzvault" + $rand
		$GetKeyVault = New-AzKeyVault -VaultName $vaultName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $GetResourceGroup.location
		Start-Sleep -s 15
		Write-Verbose "Created Azure Landing Zone key vault"
	}
	

	#
	# Checking that currently logged in user has access to key vault's data
	# If not, grant current user access to key vault's data
	#
	Write-Verbose "Checking access policy for the current user to Azure Landing Zone key vault"
	if(!($properties = Get-AzResource -ResourceId $GetKeyVault.ResourceId -ExpandProperties )){
		Write-Warning "Unable to get key vault access policy, skipping 'runAs account' creation"
		return;
	}
	if(!($properties | Where-Object {$_.Properties.accessPolicies.objectId -eq $currentUser.Id -And 
		$_.Properties.accessPolicies.permissions.certificates -Contains "Get", "List", "Update", "Create", "Import" -And 
		$_.Properties.accessPolicies.permissions.secrets -Contains "Get","List","Set","Delete"})
	) {
		Set-AzKeyVaultAccessPolicy -VaultName $GetKeyVault.VaultName -ObjectId $currentUser.Id -PermissionsToCertificates Get, List, Update, Create, Import, Delete -PermissionsToSecrets Get, List, Set, Delete -Passthru | Out-Null
		Write-Verbose "Created access policy for the current user to Azure Landing Zone key vault"
	}
	
	#
	# Checking self-signed certificate for Azure landing zone automation
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking Azure Landing Zone key vault certificate for automation account"
	if(!($AzureKeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate")){
		# Below value does not have to be accurate but must follow the proper naming convention
		$CertificateSubjectName = "CN=EU,OU=EU,O=org,L=Brussels,S=Belgium,C=BE"
		$AzureKeyVaultCertificatePolicy = New-AzKeyVaultCertificatePolicy -SubjectName $CertificateSubjectName -IssuerName "Self" -KeyType "RSA" -KeyUsage "DigitalSignature" -ValidityInMonths 12 -RenewAtNumberOfDaysBeforeExpiry 20 -KeyNotExportable:$False -ReuseKeyOnRenewal:$False
		$AzureKeyVaultCertificate = Add-AzKeyVaultCertificate -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate" -CertificatePolicy $AzureKeyVaultCertificatePolicy
		do {
			Write-Verbose "Waiting for certificate registration to complete"
			start-sleep -Seconds 10
		} until ((Get-AzKeyVaultCertificateOperation -Name "lzslzCertificate" -vaultName $GetKeyVault.vaultName).Status -eq "completed")
		Write-Verbose "Created Azure Landing Zone key vault certificate for automation account"
	}

	#
	# Checking certificate password for Azure landing zone automation
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking Azure Landing Zone key vault certificate password for automation account"
	if(!($GetKeyVaultSecret = Get-AzKeyVaultSecret -vaultName $GetKeyVault.vaultName -Name "lzslzCertificate-secret")){
		$PfxPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | foreach-object {[char]$_})
		$secretPassword = ConvertTo-SecureString -String $PfxPassword -Force -AsPlainText
		$GetKeyVaultSecret = Set-AzKeyvaultSecret -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate-secret" -SecretValue $secretPassword
		Start-Sleep -s 20
		Write-Verbose "Updated Azure Landing Zone key vault certificate password for automation account"
	}
	Start-Sleep -Seconds 10
	
	$PfxFilePath = join-path -Path (get-location).path -ChildPath "cert.pfx"
    $secret = Get-AzKeyVaultSecret -VaultName $GetKeyVault.vaultName -Name $AzureKeyVaultCertificate.Name
    $secretValueText = '';
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
    try {
	    $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    } finally {
	    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }
	$passwordValueText = '';
	$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GetKeyVaultSecret.SecretValue)
	try {
            $passwordValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }	

	$AzKeyVaultCertificatSecretBytes = [System.Convert]::FromBase64String($SecretValueText)
    $certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $certCollection.Import($AzKeyVaultCertificatSecretBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $passwordValueText)
    [System.IO.File]::WriteAllBytes($PfxFilePath, $protectedCertificateBytes)

	#
	# Checking Azure AD Application for Azure automation account
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking Azure AD application"
	if(!($GetApplicationRegistration = Get-AzADApplication | Where-Object {$_.DisplayName -eq "$($name)Automation" -And $_.identifierUri -eq "https://$(($currentUser.UserPrincipalName).Split("@")[1])/$($name)Automation"})){
		$GetApplicationRegistration = New-AzADApplication -DisplayName "$($name)Automation" -HomePage "https://$(($currentUser.UserPrincipalName).Split("@")[1])" -IdentifierUris "https://$(($currentUser.UserPrincipalName).Split("@")[1])/$($name)Automation"
		Write-Verbose "Created Azure AD application"
	}
	
	#
	# Checking credentials for Azure AD Application for Azure automation account
	# If it doesn't exist, create it
	#
	$AzKeyVaultCertificatStringValue = [System.Convert]::ToBase64String($certCollection.GetRawCertData())
	New-AzADAppCredential -ApplicationId $GetApplicationRegistration.AppId -CertValue $AzKeyVaultCertificatStringValue -StartDate $certCollection.NotBefore -EndDate $certCollection.NotAfter | Out-Null
	Write-Verbose "Checking service principal for Azure automation account"
	if(!($AzADServicePrincipal = Get-AzADServicePrincipal | Where-Object {$_.AppId -eq $GetApplicationRegistration.AppId})){		
		$AzADServicePrincipal = New-AzADServicePrincipal -ApplicationId $GetApplicationRegistration.AppId
		Write-Verbose "Created service principal for Azure automation account"
	}
	
	#
	# Checking certificate registration for Azure automation account
	# If not registered, register
	#
	Write-Verbose "Checking certificate registration for Azure automation account"
	if(!(Get-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName | Where-Object {$_.Name -eq "AzureRunAsCertificate"})){
		New-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName -Path $PfxFilePath -Name "AzureRunAsCertificate" -Password $GetKeyVaultSecret.secretValue -Exportable:$Exportable | Out-Null
		Write-Verbose "Created certificate registration for Azure automation account"
	} 
	
	#
	# Checking connection registration for Azure automation account
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking connection registration for Azure automation account"
	if(!(Get-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName)){
		$ConnectionFieldData = @{
		"ApplicationId" = $GetApplicationRegistration.AppId
		"TenantId" = (Get-AzContext).Tenant.ID
		"CertificateThumbprint" = $certCollection.Thumbprint
		"SubscriptionId" = (Get-AzContext).Subscription.ID
		}
		
		$GetAutomationAccount = New-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName -Name "AzureRunAsConnection" -ConnectionTypeName "AzureServicePrincipal" -ConnectionFieldValues $ConnectionFieldData
		Write-Verbose "Created connection registration for Azure automation account"
	}
	
	#
	# Checking role assignment for Azure automation account
	# If it doesn't exist, create it
	#
	Write-Verbose "Checking role assignment for the automation account at the subscription level"
	if(!(Get-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" | Where-Object {$_.objectId -eq $AzADServicePrincipal.Id})){
		New-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" -RoleDefinitionName "Contributor" -objectId $AzADServicePrincipal.Id | Out-Null
		Write-Verbose "Created role assignment for the automation account at the subscription level"
	}
	Write-Verbose "Checking role assignment for the automation account at the management group level"
	if(!(Get-AzRoleAssignment -scope $GetManagementGroup.id | Where-Object {$_.objectId -eq $AzADServicePrincipal.Id})){
		New-AzRoleAssignment -scope $GetManagementGroup.Id -RoleDefinitionName "Owner" -objectId $AzADServicePrincipal.Id | Out-Null
		Write-Verbose "Created role assignment for the automation account at the management group level"
	}
}
Export-ModuleMember -Function setup-RunAs