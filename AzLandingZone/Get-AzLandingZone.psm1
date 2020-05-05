Function Get-AzLandingZone {
    #
    # variables
    #
    $name = "lzslz"

    if($lzResourceGroup = Get-AzResourceGroup -ResourceGroupName $name*){
        Write-Host "Resource group correctly set" -ForegroundColor green
    }
    else {
        Write-Host "LandingZone resource group not found" -ForegroundColor Red
        exit 1
    }
}