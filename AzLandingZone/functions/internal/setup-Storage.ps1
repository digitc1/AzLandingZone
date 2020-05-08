Function setup-Storage {
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
        $GetStorageAccount = New-AzStorageAccount -ResourceGroupName $GetResourceGroup.ResourceGroupName -Name $storName -Location $AzDClocation -SkuName Standard_LRS -Kind StorageV2
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
}
Export-ModuleMember -Function setup-Storage