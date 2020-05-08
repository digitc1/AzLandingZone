Function setup-Storage {
    Param([Parameter(Mandatory=$true)][string]$name)
    
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName "*$name*")){
            Write-Host "No Resource Group for Secure Landing Zone found"
            Write-Host "Please run setup script before running the policy script"
            return 1;
    }

    #
    # Checking if Storage account for Landing Zone Logs exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Host "Checking Storage Account for Landing Zone Logs in the Secure Landing Zone"  -ForegroundColor Yellow
    while(!($GetStorageAccount = Get-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName | Where-Object {$_.StorageAccountName -Like "$name*"})){
        Write-Host "No Storage Account found for Secure Landing Zone"
        Write-Host "Creating new Storage Account for the Landing Zone Logs in the Secure Landing Zone"
        $rand = Get-Random -Minimum 1000000 -Maximum 9999999999
        $storName = $name + $rand + "sa"
        $GetStorageAccount = New-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $storName -Location $GetResourceGroup.Location -SkuName Standard_LRS -Kind StorageV2
    }
    Write-Host "Using Storage Account : "$GetStorageAccount.StorageAccountName

    #
    # Checking if log container for Landing Zone Logs already exists in the secure Landing Zone resource group
    # If it doesn't exist, create it
    #
    Write-Host "Checking storage container for Landing Zone Logs in the secure Landing Zone" -ForegroundColor Yellow
    if(!(Get-AzRmStorageContainer -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName | Where-Object {$_.Name -Like "landingzonelogs"})){
        Write-Host "No Storage container found for Secure Landing Zone logs"
        Write-Host "Creating new Storage container for the Landing Zone Logs in the Secure Landing Zone"
        New-AzRmStorageContainer -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -Name "landingzonelogs" | Out-Null
    }

        #
    # Checking immutability policy for Azure storage account
    # If storage is not immutable, set immutability to 185 days
    #
    Write-Host "Checking immutability policy" -ForegroundColor Yellow
    if(((Get-AzRmStorageContainerImmutabilityPolicy -StorageAccountName $GetStorageAccount.StorageAccountName -ResourceGroupName $GetResourceGroup.ResourceGroupName -ContainerName "landingzonelogs").ImmutabilityPeriodSinceCreationInDays) -eq 0){
    Write-Host "No immutability policy found for logs container"
    Write-Host "Creating immutability policy (default 185 days)"
    Set-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName $GetResourceGroup.ResourceGroupName -StorageAccountName $GetStorageAccount.StorageAccountName -ContainerName "landingzonelogs" -ImmutabilityPeriod 185 | Out-Null
    }
}
Export-ModuleMember -Function setup-Storage