Function Setup-Resources {
    param(
	    [Parameter(Mandatory=$true)][string]$name,
        [Parameter(Mandatory=$true)][string]$location
    )

    #
    # variables
    #
    $subscription = Get-AzSubscription | Where-Object {$_.Name -Like "SECLOG*"}

    #
    # Checking if Resource Group for secure Landing Zone already exists
    # If it doesn't exist, create it
    #
    Write-Host "Checking Resource Group for the Secure Landing Zone" -ForegroundColor Yellow
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName $name*)){
        Write-Host "No Resource Group for Secure Landing Zone found"
        Write-Host "Creating a new Resource Group for the Secure Landing Zone"
        $resourceGroupName = $name + "_rg"
        $GetResourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

    #
    # Checking if an Activity Log Profile exists for the secure Landing Zone
    # If it doesn't exist, create it
    #
    # The default Log Profile is 90 days retention for all logs
    #
    #Write-Host "Checking for ActivityLogProfile in the Secure Landing Zone" -ForegroundColor Yellow
    #Write-Host "Log profile is no longer supported and must be setup manually"

    #
    # Check if resource lock (cannot delete) is correctly set on the resource group
    # If not, apply lock
    #
    Write-Host "Checking 'CannotDelete' lock on the resource-group" -ForegroundColor Yellow
    if(!(Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"})){
        Write-Host "No lock found on the resource group"
        Write-Host "Applying 'CannotDelete' lock"
        New-AzResourceLock -LockName "LandingZoneLock" -LockLevel CannotDelete -ResourceGroupName $GetResourceGroup.ResourceGroupName -Force | Out-Null
    }

    #
    # Check if the management group for the secure Landing Zone already exist
    # If not, creates the management group lz-management-group
    #
    Write-Host "Checking Landing Zone management group" -ForegroundColor Yellow
    if(!(Get-AzManagementGroup -Erroraction "silentlycontinue "| Where-Object {$_.Name -Like "lz-management-group"})){
        Write-Host "No management group found"
        Write-Host "Creating the default management group for the Landing Zone"
        New-AzManagementGroup -GroupName "lz-management-group" -DisplayName "Landing Zone management group" | Out-Null
    }

    #
    # TODO
    # Add owners to the management group in order to avoid loss of control
    #
}
Export-ModuleMember -Function Setup-Resources