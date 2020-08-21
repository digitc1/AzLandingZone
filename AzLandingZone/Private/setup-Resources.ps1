Function Setup-Resources {
    param(
	    [Parameter(Mandatory=$true)][string]$name,
        [Parameter(Mandatory=$true)][string]$location
    )

    #
    # Checking if Resource Group for secure Landing Zone already exists
    # If it doesn't exist, create it
    #
    Write-Host "Checking Resource Group for the Secure Landing Zone" -ForegroundColor Yellow
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName $name*)){
        Write-Host "Creating a new Resource Group for the Secure Landing Zone"
        $resourceGroupName = $name + "_rg"
        $GetResourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

    #
    # Check if resource lock (cannot delete) is correctly set on the resource group
    # If not, apply lock
    #
    Write-Host "Checking 'CannotDelete' lock on the resource-group" -ForegroundColor Yellow
    if(!(Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"})){
        Write-Host "Applying 'CannotDelete' lock"
        New-AzResourceLock -LockName "LandingZoneLock" -LockLevel CannotDelete -ResourceGroupName $GetResourceGroup.ResourceGroupName -Force | Out-Null
    }

    #
    # Check if the management group for the secure Landing Zone already exist
    # If not, creates the management group lz-management-group
    #
    Write-Host "Checking Landing Zone management group" -ForegroundColor Yellow
    if(!(Get-AzManagementGroup -Erroraction "silentlycontinue "| Where-Object {$_.Name -Like "lz-management-group"})){
        Write-Host "Creating the default management group for the Landing Zone"
        New-AzManagementGroup -GroupName "lz-management-group" -DisplayName "Landing Zone management group" | Out-Null
        Start-Sleep -s 20
    }
}
Export-ModuleMember -Function Setup-Resources