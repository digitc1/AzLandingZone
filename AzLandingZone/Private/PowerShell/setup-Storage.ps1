Function setup-Storage {
    Param(
        [Parameter(Mandatory=$true)][string]$name,
        [int]$retentionPeriod = 185
    )
    
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found" -ForegroundColor Red
            Write-Host "Run setup script before running this script"
            return;
    }

    #
    # Checking if Storage account for Landing Zone Logs exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Host "Checking Storage Account for Landing Zone Logs in the Secure Landing Zone"  -ForegroundColor Yellow
    if(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "$name*"})){
        Write-Host "Creating Landing Zone storage account"
        $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
        $storName = $name + $rand + "sa"
        $GetStorageAccount = New-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $storName -Location $GetResourceGroup.Location -SkuName Standard_LRS -Kind StorageV2
    }

    #
    # Set the context to current storage account
    # Required for additional configuration
    #
    Write-Host "Setting context to current storage account" -ForegroundColor Yellow
    $context = New-AzStorageContext -StorageAccountName $GetStorageAccount.StorageAccountName

    #
    # Checking if log container for Landing Zone Logs already exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Host "Checking storage container for Landing Zone Logs in the secure Landing Zone" -ForegroundColor Yellow
    if(!(Get-AzStorageContainer -Context $context | Where-Object {$_.Name -Like "landingzonelogs"})){
        New-AzStorageContainer -Context $context -Name "landingzonelogs" | Out-Null
        Write-Host "Created 'landingzonelogs' for Landing Zone logs"
    }

    #
    # Checking immutability policy for Azure storage account
    # If storage is not immutable, set immutability to 185 days
    # TODO : Replace AzureRm with Az when feature is available
    #
    Write-Host "Checking immutability policy" -ForegroundColor Yellow
    if(((Get-AzRmStorageContainerImmutabilityPolicy -StorageAccountName $GetStorageAccount.StorageAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -ContainerName "landingzonelogs").ImmutabilityPeriodSinceCreationInDays) -eq 0){
        $policy = Set-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -ContainerName "landingzonelogs" -ImmutabilityPeriod $retentionPeriod
        Lock-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -ContainerName "landingzonelogs" -Etag $policy.Etag
        Write-Host "Created immutability policy for $retentionPeriod days"
    }
}
Export-ModuleMember -Function setup-Storage
