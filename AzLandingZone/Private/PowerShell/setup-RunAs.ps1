Function setup-RunAs {
    param(
        [string]$name = "lzslz",
        [string]$managementGroup = "lz-management-group"
    )

    $SubscriptionId = (Get-AzContext).Subscription.Id
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
        Write-Host "No Resource Group for Secure Landing Zone found"
        return;
    }
    if(!($GetAutomationAccount = Get-AzAutomationAccount | Where-Object {$_.ResourceGroupName -like $GetResourceGroup.ResourceGroupName} )){
        Write-Host "No Automation account for Secure Landing Zone found"
        return;
    }
    if(!($GetManagementGroup = Get-AzManagementGroup | Where-Object {$_.Name -Like "lz-management-group"} )){
        Write-Host "No Resource Group for Secure Landing Zone found"
        return;
    }
    $Location = $GetResourceGroup.Location
    $scope = $GetManagementGroup.Id

    Write-Host -Foreground Yellow "Checking Azure LandingZone key vault"
    if (!($GetKeyVault = Get-AzKeyVault | Where-Object {$_.ResourceGroupName -Like $GetResourceGroup.ResourceGroupName} )) {
        $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
        $keyVaultName = "lzslzvault" + $rand
        $GetKeyVault = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $GetResourceGroup.ResourceGroupName -Location $Location
        Write-Host "Created Azure LandingZone key vault"
    }

    ### grant current user access to key vault
    # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
    $servicePrincipalId = az ad signed-in-user show --query objectId -o tsv
    Start-Sleep -s 5
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $GetKeyVault.ResourceGroupName -VaultName $GetKeyVault.VaultName -ObjectId $servicePrincipalId -PermissionsToCertificates ("list","get","create") -PermissionsToKeys ("list","get","create") -PermissionsToSecrets ("list","get","set") -PermissionsToStorage ("list","get","set")

    #### creating SP and granting access to KeyVault
    if(!(Get-AzADApplication | Where-Object {$_.DisplayName -Like "lzslzautomation"})){
        [String] $ApplicationDisplayName = $GetAutomationAccount.AutomationAccountName
        [String] $SelfSignedCertPlainPassword = [Guid]::NewGuid().ToString().Substring(0, 8) + "!"
        [int] $NoOfMonthsUntilExpired = 36

        $CertifcateAssetName = "AzureRunAsCertificate"
        $CertificateName = $GetAutomationAccount.AutomationAccountName + $CertifcateAssetName
        $PfxCertPathForRunAsAccount = Join-Path $HOME ($CertificateName + ".pfx")
        $PfxCertPlainPasswordForRunAsAccount = $SelfSignedCertPlainPassword
        $CerCertPathForRunAsAccount = Join-Path $HOME ($CertificateName + ".cer")

        Write-Output "Generating the cert using Keyvault..."

        $certSubjectName = "cn=" + $certificateName

        $Policy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $certSubjectName -IssuerName "Self" -ValidityInMonths $noOfMonthsUntilExpired -ReuseKeyOnRenewal
        $AddAzureKeyVaultCertificateStatus = Add-AzKeyVaultCertificate -VaultName $GetKeyVault.VaultName -Name $certificateName -CertificatePolicy $Policy

        While ($AddAzureKeyVaultCertificateStatus.Status -eq "inProgress") {
            Start-Sleep -s 10
            $AddAzureKeyVaultCertificateStatus = Get-AzKeyVaultCertificateOperation -VaultName $GetKeyVault.VaultName -Name $certificateName
        }

        if ($AddAzureKeyVaultCertificateStatus.Status -ne "completed") {
            Write-Error -Message "Key vault cert creation is not sucessfull and its status is: $status.Status"
        }

        $secretRetrieved = Get-AzKeyVaultSecret -VaultName $GetKeyVault.VaultName -Name $certificateName
        $pfxBytes = [System.Convert]::FromBase64String($secretRetrieved.SecretValueText)
        $certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
        $certCollection.Import($pfxBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

        #Export the .pfx file
        $protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $PfxCertPlainPasswordForRunAsAccount)
        [System.IO.File]::WriteAllBytes($PfxCertPathForRunAsAccount, $protectedCertificateBytes)

        #Export the .cer file
        $cert = Get-AzKeyVaultCertificate -VaultName $GetKeyVault.VaultName -Name $certificateName
        $certBytes = $cert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        [System.IO.File]::WriteAllBytes($CerCertPathForRunAsAccount, $certBytes)

        Write-Output "Creating service principal..."
        # Create Service Principal
        $PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $PfxCertPlainPasswordForRunAsAccount)

        $keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())
        $KeyId = [Guid]::NewGuid()

        $startDate = Get-Date
        $endDate = (Get-Date $PfxCert.GetExpirationDateString()).AddDays(-1)

        # Use Key credentials and create AAD Application
        $Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $applicationDisplayName) -IdentifierUris ("http://" + $KeyId)
        New-AzADAppCredential -ApplicationId $Application.ApplicationId -CertValue $keyValue -StartDate $startDate -EndDate $endDate
        New-AzADServicePrincipal -ApplicationId $Application.ApplicationId

        # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
        Start-Sleep -s 15

        $NewRole = $null
        $Retries = 0;
        While ($NewRole -eq $null -and $Retries -le 6) {
            New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId -scope $scope -ErrorAction SilentlyContinue
            Start-Sleep -s 10
            $NewRole = Get-AzRoleAssignment -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
            $Retries++;
        }

        Write-Output "Creating Certificate in the Asset..."
        # Create the automation certificate asset
        $CertPassword = ConvertTo-SecureString $PfxCertPlainPasswordForRunAsAccount -AsPlainText -Force
        Remove-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -automationAccountName $GetAutomationAccount.AutomationAccountName -Name $certifcateAssetName -ErrorAction SilentlyContinue
        New-AzAutomationCertificate -ResourceGroupName $GetResourceGroup.ResourceGroupName -automationAccountName $GetAutomationAccount.AutomationAccountName -Path $PfxCertPathForRunAsAccount -Name $certifcateAssetName -Password $CertPassword -Exportable | write-verbose

        # Populate the ConnectionFieldValues
        $ConnectionTypeName = "AzureServicePrincipal"
        $ConnectionAssetName = "AzureRunAsConnection"
        $ApplicationId = $Application.ApplicationId
        $SubscriptionInfo = Get-AzSubscription -SubscriptionId $SubscriptionId
        $TenantID = $SubscriptionInfo | Select-Object TenantId -First 1
        $Thumbprint = $PfxCert.Thumbprint
        $ConnectionFieldValues = @{"ApplicationId" = $ApplicationID; "TenantId" = $TenantID.TenantId; "CertificateThumbprint" = $Thumbprint; "SubscriptionId" = $SubscriptionId}
        # Create a Automation connection asset named AzureRunAsConnection in the Automation account. This connection uses the service principal.

        Write-Output "Creating Connection in the Asset..."
        Remove-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -automationAccountName $GetAutomationAccount.AutomationAccountName -Name $connectionAssetName -Force -ErrorAction SilentlyContinue
        New-AzAutomationConnection -ResourceGroupName $GetResourceGroup.ResourceGroupName -automationAccountName $GetAutomationAccount.AutomationAccountName -Name $connectionAssetName -ConnectionTypeName $connectionTypeName -ConnectionFieldValues $connectionFieldValues

        Write-Output "RunAsAccount Creation Completed..."
    }
    Remove-AzKeyVaultAccessPolicy -ResourceGroupName $GetKeyVault.ResourceGroupName -VaultName $GetKeyVault.VaultName -ObjectId $servicePrincipalId
}
Export-ModuleMember -Function setup-RunAs