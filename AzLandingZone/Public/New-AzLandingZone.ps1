Function New-AzLandingZone {
    <#
        .SYNOPSIS
        Installs all the components of the Landing Zone
        .DESCRIPTION
        Installs all the components of the Landing Zone
        .PARAMETER Name
        String to identify Landing Zone resource group and resources
        .PARAMETER autoUpdate
        Switch to enable auto-update. If no value is provided then default to $false.
        .PARAMETER SOC
        Enter the name of the SOC to connect to. If no value is provided then default to none.
        .PARAMETER location
        Enter a location to install the Landing Zone. If no value is provided then default to West Europe.
        .PARAMETER enableSentinel
        Switch to enable installation of Azure Sentinel. If no value is provided then default to $false. This parameter is overwritten to $true if using parameter "-SOC DIGIT".
        .PARAMETER enableEventHub
        Switch to enable installation of event hub namespace. If no value is provided then default to $false. This parameter is overwritten to $true if using parameter "-SOC CERTEU".
        .PARAMETER managementGroup
        Enter the name for AzLandingZone management group. If the management group already exist, it is reused for AzLandingZone.
        .PARAMETER retentionPeriod
        Enter the number of days to retain the logs in legal hold. If not value is provided then default to 185 days (6 months). This parameters cannot be less than 185 days.
        .PARAMETER securityContacts
        Enter a coma-separated list of users to notify in case of security alerts.
        .EXAMPLE
        New-AzLandingZone
        Install the default components of the Landing Zone with default values.
        .EXAMPLE
        New-AzLandingZone -SOC "DIGIT" -autoupdate $true -location "northeurope"
        Install the default components of the Landing Zone + log analytics workspace and Azure sentinel in region North Europe. Enables auto-update and connectivity for DIGIT-CLOUDSEC team.
        .EXAMPLE
        New-AzLandingZone -EnableSentinel $true -retentionPeriod 365
        Install the default components of the Landing Zone + log analytics workspace and Azure sentinel. Retention policy for legal hold is set to 365 days (storage account only).
        .EXAMPLE
        New-AzLandingZone -EnableEventHub $true -securityContacts "alice@domain.com,bob@domain.com"
        Install the default components of the Landing Zone + event hub namespace with a specific event hub and key. The users "alice@domain.com" and "bob@domain.com" are used for security notifications.
    #>
    Param (
		[bool]$autoUpdate = $false,
		[ValidateSet("DIGIT", "CERTEU", "None")][string]$SOC = "None",
		[ValidateSet("westeurope", "northeurope", "francecentral", "germanywestcentral")][string]$location = "westeurope",
		[bool]$enableSentinel = $false,
        [bool]$enableEventHub = $false,
        [string]$managementGroup = "lz-management-group",
        [string]$name = "lzslz",
		[int]$retentionPeriod = 185,
        [String[]]$securityContacts
	)

    register-ResourceProvider

    #
    # variables
    #
    Write-Host "Creating variables and launching creation" -ForegroundColor Yellow
    $context = Get-AzContext
    if(!($context.Subscription.Name -Like "*SECLOG*")){
        Write-Host "Context is not set to SecLog subscription. Landing Zone resources will be deployed to the current context."
        Write-Host $context.Subscription.Name
        [void](Read-Host 'Press Enter to continue or "ctrl + C" to cancel the installation.')
    }
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

    $setupResourcesResult  = setup-Resources -Name $name -Location $location -managementGroup $managementGroup -autoUpdate $autoUpdate
    setup-Storage -Name $name -retentionPeriod $retentionPeriod
    $setupLogPipelineResult = setup-LogPipeline -Name $name -enableSentinel $enableSentinel -enableEventHub $enableEventHub

    enable-AutomationAccountChangeTrackinAndInventory `
        -Name $name `
        -AutomationAccountName $setupResourcesResult.automationAccount.AutomationAccountName `
        -lawName $setupLogPipelineResult.law.Name

    Set-LzActiveDirectoryDiagnosticSettings -name $name

    #setup-SubscriptionContacts -SOC $SOC -securityContacts $securityContacts
    # TODO : review policy
    setup-PolicyGithub -Name $name -managementGroup $managementGroup
    setup-Policy -Name $name -managementGroup $managementGroup -enableSentinel $enableSentinel
    setup-MonitoringAgent -Name $name -managementGroup $managementGroup
    #setup-Lighthouse -SOC $SOC -managementGroup $managementGroup
    if($enableSentinel) {
        setup-Sentinel -Name $name 
    }
}
Export-ModuleMember -Function New-AzLandingZone
