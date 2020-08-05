Function New-AzLandingZone {
    Param (
		[bool]$autoupdate = $true,
		[ValidateSet("DIGIT", "CERTEU", "None")][string]$SOC = "None",
		[ValidateSet("westeurope", "northeurope", "francecentral", "germanywestcentral")][string]$location = "westeurope",
		[bool]$enableSentinel = $false,
		[bool]$enableEventHub = $false,
		[int]$retentionPeriod = 185,
        [String[]]$securityContacts
	)

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    #if(Test-AzLandingZone){
    #    Write-Host "Pre-requisite for Azure LandingZone are not met."
    #    Write-Host "Run 'Test-AzLandingZone -verbose' for additional information."
    #}

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
        [void](Read-Host 'Press Enter to continue or 'ctrl + C' to cancel the installation.')
    }
    $name = "lzslz"
	if($SOC -eq "DIGIT"){
		$enableSentinel = $true
	}
	if($SOC -eq "CERTEU"){
		$enableEventHub = $true
	}
	if($LZLocation = (Get-AzResourceGroup | where-Object {$_.ResourceGroupName -Like "$name*"}).Location){
		$location = $LZLocation
	}
	if($retentionPeriod -lt 185){
		$retentionPeriod = 185
	}

    setup-Resources -Name $name -Location $location
    setup-Storage -Name $name -retentionPeriod $retentionPeriod
    setup-LogPipeline -Name $name -enableSentinel $enableSentinel -enableEventHub $enableEventHub
    if($autoupdate -eq $true) {
        setup-Automation -Name $name
    }

    setup-SubscriptionContacts -SOC $SOC -securityContacts $securityContacts
    setup-Policy -Name $name
    setup-Lighthouse -SOC $SOC
}
Export-ModuleMember -Function New-AzLandingZone