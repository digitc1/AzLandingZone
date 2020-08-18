Function Update-AzLandingZone {
    <#
        .SYNOPSIS
        Update Landing Zone policies and resources to latest configuration
        .DESCRIPTION
        Update Landing Zone policies and resources to latest configuration
        .EXAMPLE
        Update-AzLandingZone
    #>
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    if(Test-AzLandingZone){
        Write-Host "Pre-requisite for Azure LandingZone are not met."
        Write-Host "Run 'Test-AzLandingZone -verbose' for additional information."
    }

    #
    # Checking registrations and prerequisites for the Landing Zone
    # Registration can take few minutes
    #
    setup-prerequisites

    #
    # variables
    #
    Write-Host "Creating variables and launching creation" -ForegroundColor Yellow
    $context = Get-AzContext
    $name = "lzslz"
    if(!($GetResourceGroup = Get-AzResourceGroup | where-Object {$_.ResourceGroupName -Like "$name*"})){
        Write-Host "The Azure Landing Zone could not be found in the current context. Switch context with 'Set-AzContext -SubscriptionId <id>' cmdlet or install the Landing Zone first" -ForegroundColor Red
        exit
    }
    $location = $GetResourceGroup.Location

    setup-Resources -Name $name -Location $location
    setup-Storage -Name $name
    setup-Policy -Name $name
}
Export-ModuleMember -Function Update-AzLandingZone