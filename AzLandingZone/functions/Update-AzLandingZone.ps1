workflow work {
    parallel {
        setup-Storage -Name $name
        setup-LogPipeline -Name $name -SOC $SOC
        setup-Lighthouse -SOC $SOC
    }
}
Function Update-AzLandingZone {
    Param(
        [ValidateSet("DIGIT", "CERTEU", "None")]
        [string] $SOC,
        [Parameter(Mandatory=$true)]
        [bool] $autoupdate,
        [ValidateSet("westeurope", "northeurope", "francecentral", "germanywestcentral")]
        [string] $location
    )

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    if(!(Test-AzLandingZone)){
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
    $subscription = Get-AzSubscription | where-Object {$_.Name -Like "DIGIT_C1*"}
    $context = Set-AzContext -SubscriptionId $subscription.Id
    $name = "lzslz"
    $locations = (Get-AzLocation).Location
    $locations += "global"
    if(!($location) -And !(Get-AzResourceGroup | where-Object {$_.ResourceGroupName -Like "$name*"})){
        $location = "westeurope"
    }

    setup-Resources -Name $name -Location $location
    work

    if($autoupdate -eq $true) {
        setup-Automation -Name $name
    }

    setup-Policy -Name $name
}
Export-ModuleMember -Function Update-AzLandingZone