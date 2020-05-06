Function New-AzLandingZone {
    Param(
        [ValidateSet("DIGIT", "CERTEU", "None")]
        [string] $SOC,
        [Parameter(Mandatory=$true)]
        [bool] $autoupdate
    )

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

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

    setup-Resources -Name $name

    if($autoupdate) {
        setup-automation
    }

    setup-Policies -Name $name

    setup-Lighthouse


    Write-Host "The parameters are as follow"
    Write-Host "Name= $name"
    Write-Host "SOC= $SOC"
    Write-Host "auto-update= $autoupdate"
}
Export-ModuleMember -Function New-AzLandingZone