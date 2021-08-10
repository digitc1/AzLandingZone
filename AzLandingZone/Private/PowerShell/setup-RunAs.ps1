Function setup-RunAs {
    param(
		[string]$name = "lzslz",
		[string]$managementGroup = "lz-management-group"
	)
	
	if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*" )){
		Write-Host "No Resource Group for the Secure Landing Zone found"
		return;
	}
	if(!($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.ResourceGroupName -like $GetResourceGroup.ResourceGroupName} )){
		Write-Host "No Automation account for Secure Landing Zone found"
		return;
	}
	if(!($GetManagementGroup = Get-AzManagementGroup | Where-Object {$_.Name -like "lz-management-group"})){
		Write-Host "No management group for the secure Landing Zone found"
		return;
	}
	$servicePrincipalId = az ad signed-in-user show --query objectId -o tsv
	
	Write-Host -Foreground Yellow "Checking Azure Landing Zone key vault"
	if(!($GetKeyVault = Get-AzKeyVault | Where-Object {$_.ResourceGroupName -Like $GetResourceGroup.ResourceGroupName})){
		$rand = Get-Random -Minimum 1000000 -Maximum 9999999999
		$vaultName = "lzslzvault" + $rand
		$GetKeyVault = New-AzKeyVault -VaultName $vaultName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $GetResourceGroup.location
		Write-Host "Created Azure Landing Zone key vault"
	}
	Start-Sleep -s 15

	# grant current user access to the key vault
	Write-Host -Foreground Yellow "Checking access policy for the current user to Azure Landing Zone key vault"
	if(!($accessPolicy = Get-AzResource -ResourceId $GetKeyVault.ResourceId -ExpandProperties | Where-Object {$_.Properties.accessPolicies.objectId -eq $servicePrincipalId})) {
		Set-AzKeyVaultAccessPolicy -VaultName $GetKeyVault.VaultName -ObjectId $servicePrincipalId -PermissionsToKeys Get,List,Update,Create,Import,Delete,Recover,Backup,Restore -PermissionsToCertificates Get, List, Update, Create, Import, Delete, Recover, Backup, Restore, ManageContacts,ManageIssuers, GetIssuers, ListIssuers, SetIssuers, DeleteIssuers -PermissionsToSecrets Get,List,Set,Delete,Recover,Backup,Restore -Passthru | Out-Null
		Start-Sleep -seconds 15
		Write-Host "Created access policy for the current user to Azure Landing Zone key vault"
	}
	
	Write-Host -Foreground Yellow "Checking Azure Landing Zone key vault certificate for automation account"
	if(!($AzureKeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate")){
		$CertificateSubjectName = "CN=EU,OU=EU,O=org,L=Brussels,S=Belgium,C=BE"
		$AzureKeyVaultCertificatePolicy = New-AzKeyVaultCertificatePolicy -SubjectName $CertificateSubjectName -IssuerName "Self" -KeyType "RSA" -KeyUsage "DigitalSignature" -ValidityInMonths 12 -RenewAtNumberOfDaysBeforeExpiry 20 -KeyNotExportable:$False -ReuseKeyOnRenewal:$False
		$AzureKeyVaultCertificate = Add-AzKeyVaultCertificate -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate" -CertificatePolicy $AzureKeyVaultCertificatePolicy
		do {
			start-sleep -Seconds 20
		} until ((Get-AzKeyVaultCertificateOperation -Name "lzslzCertificate" -vaultName $GetKeyVault.vaultName).Status -eq "completed")
		Write-Host "Created Azure Landing Zone key vault certificate for automation account"
	}
	
	Write-Host "Exporting certificate"
	Write-Host -Foreground Yellow "Checking Azure Landing Zone key vault certificate password for automation account"
	if(!($GetKeyVaultSecret = Get-AzKeyVaultSecret -vaultName $GetKeyVault.vaultName -Name "lzslzCertificate-secret")){
		$PfxPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | foreach-object {[char]$_})
		$secretPassword = ConvertTo-SecureString -String $PfxPassword -Force -AsPlainText
		$GetKeyVaultSecret = Set-AzKeyvaultSecret -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate-secret" -SecretValue $secretPassword
		Start-Sleep -s 20
		Write-Host "Updated Azure Landing Zone key vault certificate password for automation account"
	}
	Start-Sleep -Seconds 10
	#$PfxPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | foreach-object {[char]$_})
	#$secretPassword = ConvertTo-SecureString -String $PfxPassword -Force -AsPlainText
	#Set-AzKeyvaultSecret -VaultName $GetKeyVault.vaultName -Name "lzslzCertificate-secret" -SecretValue $secretPassword
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

	Write-Host -Foreground Yellow "Checking Azure AD application"
	if(!($GetApplicationRegistration = Get-AzADApplication | Where-Object {$_.DisplayName -eq "lzslzAutomation" -And $_.identifierUris -eq "https://lzslzAutomation"})){
		$GetApplicationRegistration = New-AzADApplication -DisplayName "lzslzAutomation" -HomePage "http://lzslzAutomation" -IdentifierUris "https://lzslzAutomation"
		Write-Host "Created Azure AD application"
	}
	
	
	$AzKeyVaultCertificatStringValue = [System.Convert]::ToBase64String($certCollection.GetRawCertData())
	New-AzADAppCredential -ApplicationId $GetApplicationRegistration.ApplicationId -CertValue $AzKeyVaultCertificatStringValue -StartDate $certCollection.NotBefore -EndDate $certCollection.NotAfter | Out-Null
	Write-Host -Foreground Yellow "Checking service principal for Azure automation account"
	if(!($AzADServicePrincipal = Get-AzADServicePrincipal | Where-Object {$_.ApplicationId -eq $GetApplicationRegistration.ApplicationId})){		
		$AzADServicePrincipal = New-AzADServicePrincipal -ApplicationId $GetApplicationRegistration.ApplicationId -SkipAssignment
		Write-Host "Created service principal for Azure automation account"
	}
	
	Write-Host -Foreground Yellow "Checking certificate registration for Azure automation account"
	if(!($GetAutomationCertificate = Get-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName | Where-Object {$_.Name -eq "AzureRunAsCertificate"})){
		$GetAutomationCertificate = New-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName -Path $PfxFilePath -Name "AzureRunAsCertificate" -Password $GetKeyVaultSecret.secretValue -Exportable:$Exportable
		Write-Host "Created certificate registration for Azure automation account"
	} 
	
	Write-Host -Foreground Yellow "Checking connection registration for Azure automation account"
	if(!($GetAutomationConnection = Get-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName)){
		$ConnectionFieldData = @{
		"ApplicationId" = $GetApplicationRegistration.ApplicationId
		"TenantId" = (Get-AzContext).Tenant.ID
		"CertificateThumbprint" = $certCollection.Thumbprint
		"SubscriptionId" = (Get-AzContext).Subscription.ID
		}
		
		$GetAutomationAccount = New-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -AutomationAccountName $GetAutomationAccount.automationAccountName -Name "AzureRunAsConnection" -ConnectionTypeName "AzureServicePrincipal" -ConnectionFieldValues $ConnectionFieldData
		Write-Host "Created connection registration for Azure automation account"
	}
	
	Write-Host -Foreground Yellow "Checking role assignment for the automation account at the subscription level"
	if(!($GetRoleAssignment = Get-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" | Where-Object {$_.objectId -eq $AzADServicePrincipal.Id})){
		New-AzRoleAssignment -scope "/subscriptions/$((Get-AzContext).Subscription.subscriptionId)" -RoleDefinitionName "Contributor" -objectId $AzADServicePrincipal.Id
		Write-Host "Created role assignment for the automation account at the subscription level"
	}
	
	Write-Host -Foreground Yellow "Checking role assignment for the automation account at the management group level"
	if(!($GetRoleAssignment = Get-AzRoleAssignment -scope $GetManagementGroup.id | Where-Object {$_.objectId -eq $AzADServicePrincipal.Id})){
		New-AzRoleAssignment -scope $GetManagementGroup.Id -RoleDefinitionName "Owner" -objectId $AzADServicePrincipal.Id
		Write-Host "Created role assignment for the automation account at the management group level"
	}
}
Export-ModuleMember -Function setup-RunAs