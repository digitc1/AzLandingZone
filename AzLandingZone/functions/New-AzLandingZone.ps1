Function New-AzLandingZone {
    Param(
        [ValidateSet("DIGIT", "CERTEU", "None")]
        [string] $SOC,
        [Parameter(Mandatory=$true)]
        [bool] $autoupdate,
        [ValidateSet("westeurope", "northeurope", "francecentral", "germanywestcentral")]
        [string] $location
    )

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    [Environment]::Username)

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
    if(!($context.Subscription.Name -Like "SECLOG*")){
        Write-Host "Context is not set to SecLog subscription. Landing Zone resources will be deployed to the current context."
        Write-Host $context.Subscription.Name
        Write-Host "Press 'enter' to continue or 'ctrl + C' to cancel the installation."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    $name = "lzslz"
    #$locations = (Get-AzLocation).Location
    #$locations += "global"
    #if(!($location) -And !(Get-AzResourceGroup | where-Object {$_.ResourceGroupName -Like "$name*"})){
    #    $location = "westeurope"
    #}

    setup-Resources -Name $name -Location $location
    setup-Storage -Name $name
    setup-LogPipeline -Name $name -SOC $SOC
    if($autoupdate -eq $true) {
        setup-Automation -Name $name
    }

    setup-SubscriptionContacts -SOC $SOC
    setup-Policy -Name $name
    setup-Lighthouse -SOC $SOC
}
Export-ModuleMember -Function New-AzLandingZone