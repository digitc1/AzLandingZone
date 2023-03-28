Function Setup-Resources {
    [cmdletbinding()]

    param(
	    [Parameter(Mandatory=$true)][string]$name,
        [Parameter(Mandatory=$true)][string]$location,
        [Parameter(Mandatory=$true)][string]$managementGroup,
        [Parameter(Mandatory=$true)][bool]$autoUpdate
    )

    Write-Host "Checking Azure Landing Zone Resources" -ForegroundColor Yellow
    #
    # Check if the management group for the secure Landing Zone already exist
    # If not, creates the management group lz-management-group
    #
    Write-Verbose "Checking Landing Zone management group"
    if(!(Get-AzManagementGroup -ErrorAction silentlyContinue | Where-Object {$_.Name -Like $managementGroup})){
        Write-Verbose "Creating the default management group for the Landing Zone"
        New-AzManagementGroup -GroupId $managementGroup -DisplayName "Landing Zone management group" | Out-Null
        #Start-Sleep -s 20
    }

    #
    # Checking if Resource Group for secure Landing Zone already exists
    # If it doesn't exist, create it
    #
    Write-Verbose "Checking Azure Landing Zone resource group"
    if(!($GetResourceGroup = Get-AzResourceGroup -ResourceGroupName $name*)){
        Write-Verbose "Creating a new Resource Group for the Secure Landing Zone"
        $resourceGroupName = $name + "_rg"
        $GetResourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

    #
    # Check if resource lock (cannot delete) is correctly set on the resource group
    # If not, apply lock
    #
    Write-Verbose "Checking 'CannotDelete' lock on the resource-group"
    if(!(Get-AzResourceLock | Where-Object {$_.Name -Like "LandingZoneLock"})){
        Write-Verbose "Applying 'CannotDelete' lock"
        New-AzResourceLock -LockName "LandingZoneLock" -LockLevel CannotDelete -ResourceGroupName $GetResourceGroup.ResourceGroupName -Force | Out-Null
    }


    #
    # Create the Automation Account (to link to Log Analytics Workspace)
    #
    $psAutomationAccount = set-AutomationAccount -Name $name
    if($psAutomationAccount -eq $null){
        Write-Error "Something went wrong while creating Automation Account"
        return
    }
    
    #
    # Check if the auto-update feature was requested
    # If so, run the auto-update setup
    #
    if($autoupdate -eq $true) {
        setup-Automation -Name $name -managementGroup $managementGroup
    }

    $result = [PSCustomObject]@{
        automationAccount = $psAutomationAccount
    }
    
    return $result
}
Export-ModuleMember -Function Setup-Resources