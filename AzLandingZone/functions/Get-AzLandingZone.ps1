#
# Exit code
# 0: Landing zone installed and up to date
# 1: Landing zone installed, updates available
# 2: Landing zone not installed

Function Get-AzLandingZone {
    #
    # Azure modules
    #
    Install-Module AzSentinel -Force

    #
    # variables
    #
    $name = "lzslz"

    #
    # Check resources
    #
    if($lzResourceGroup = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -Like "$name*"}){
        Write-Host "Resource group properly configured" -ForegroundColor Green
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        exit 2
    }

    if($lzStorageAccount = Get-AzStorageAccount -ResourceGroupName $lzResourceGroup.ResourceGroupName) {
        if($lzStorageContainer = Get-AzStorageContainer -ResourceGroupName $lzResourceGroup.ResourceGroupName -StorageAccountName $lzStorageAccount.StorageAccountName){
            if((Get-AzStorageContainerImmutabilityPolicy -ResourceGroupName $lzResourceGroup.ResourceGroupName -StorageAccountName $lzStorageAccount.StorageAccountName -ContainerName $lzStorageContainer.Name).ImmutabilityPeriodSinceCreationInDays -gt 180){
                Write-Host "Storage Account properly configured" -ForegroundColor Green
            }
            else {
                Write-Host "Immutability policy for logs storage is not set" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Storage account for Landing Zone Logs is not set" -ForegroundColor Red
            Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
            exit 2
        }
    }
    else {
        Write-Host "Landing Zone not installed" -ForegroundColor Red
        Write-Host "Run 'New-AzLandingZone' cmdlet to configure the Landing Zone" -ForegroundColor Red
        exit 2
    }
}
Export-ModuleMember -Function Get-AzLandingZone