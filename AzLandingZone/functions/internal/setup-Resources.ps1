Function Setup-Resources {
    param(
	    [Parameter(Mandatory=$true)][string] $name,
        [Parameter(Mandatory=$true)][string] $location
    )
    
    #
    # Azure modules
    #
    # Install-Module AzSentinel -Force

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
    Write-Host "Using Resource Group : "$GetResourceGroup.ResourceGroupName

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
        Write-Host "Created resource lock on the resource group"
    }

    #
    # Check if the management group for the secure Landing Zone already exist
    # If not, creates the management group lz-management-group
    #
    Write-Host "Checking Landing Zone management group" -ForegroundColor Yellow
    if(!(Get-AzManagementGroup | Where-Object {$_.Name -Like "lz-management-group"})){
        Write-Host "No management group found"
        Write-Host "Creating the default management group for the Landing Zone"
        New-AzManagementGroup -GroupName "lz-management-group" -DisplayName "Landing Zone management group" | Out-Null
    }

    $children = (Get-AzManagementGroup -GroupName "lz-management-group" -Expand).Children
    Get-AzSubscription | ForEach-Object {
        if ($_.Name -notin $children.DisplayName){
            if($_.Name -Like "SecLog*"){
                New-AzManagementGroupSubscription -GroupName "lz-management-group" -SubscriptionId $_.Id
            }
            else{
                Write-Host "Do you want to onboard the following subscription: " $_.Name
                $param = read-Host "enter y or n (default No)"
                if($param -Like "y"){
                    Write-Host "Onboarding the subscription"
                    New-AzManagementGroupSubscription -GroupName "lz-management-group" -SubscriptionId $_.Id
                    Write-Host "The following subscription is now part of the Landing Zone: "$_.Name
                }
            }
        }
    }

    #
    # TODO
    # Add owners to the management group in order to avoid loss of control
    #
}
Export-ModuleMember -Function Setup-Resources