Function setup-Storage {
    [cmdletbinding()]

    Param(
        [string]$name = "lzslz",
        [int]$retentionPeriod = 185
    )
    
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Error "No Resource Group for Secure Landing Zone found" -ForegroundColor Red
            Write-Error "Run setup script before running this script"
            return;
    }

    Write-Host "Checking Storage Account for Landing Zone Logs in the Secure Landing Zone"  -ForegroundColor Yellow
    #
    # Checking if Storage account for Landing Zone Logs exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking Azure Landing Zone Storage Account"
    if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "$name*"})){
        Write-Verbose "Creating Azure Landing Zone storage account"
        $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
        $storName = $name + $rand + "sa"
        $GetStorageAccount = New-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $storName -Location $GetResourceGroup.Location -SkuName Standard_LRS -Kind StorageV2
    }
    $context = New-AzStorageContext -StorageAccountName $GetStorageAccount.StorageAccountName

    #
    # Checking if log container for Landing Zone Logs already exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking Azure Landing Zone storage container"
    if(!(Get-AzStorageContainer -Context $context | Where-Object {$_.Name -Like "landingzonelogs"})){
        New-AzStorageContainer -Context $context -Name "landingzonelogs" | Out-Null
        Write-Verbose "Created 'landingzonelogs' for Landing Zone logs"
    }

    #
    # Checking immutability policy for Azure storage account
    # If storage is not immutable, set immutability to 185 days
    # Migrate Immutability policy to Az module instead of AzureRM
    #
    if($name -Like "*test*"){
        Write-Verbose "In test mode - so do not create an immutability policy for storage account"
    } else {    
        Write-Verbose "Checking Azure Landing Zone Storage account immutability policy"
        if(((Get-AzRmStorageContainerImmutabilityPolicy -StorageAccountName $GetStorageAccount.StorageAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -ContainerName "landingzonelogs").ImmutabilityPeriodSinceCreationInDays) -eq 0){
            #$blob = Set-AzStorageBlobImmutabilityPolicy -Container $container.Name -PolicyMode Unlocked -ExpiresOn (GetDate).AddDays($retentionPeriod)
            $policy = Set-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -ContainerName "landingzonelogs" -ImmutabilityPeriod $retentionPeriod
            Lock-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -ContainerName "landingzonelogs" -Etag $policy.Etag -Force
            Write-Verbose "Created immutability policy for $retentionPeriod days"
        }
    }
}
Export-ModuleMember -Function setup-Storage
