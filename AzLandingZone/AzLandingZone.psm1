$moduleList = @(
	@{
		Name = 'Az.Accounts';
		Version = '2.11.2'
	}
	@{
		Name = 'Az.EventHub';
		Version = '3.2.1'
	}
	@{
		Name = 'Az.Resources';
		Version = '6.5.2'
	}
	@{
		Name = 'Az.Storage';
		Version = '5.4.0'
	}
)

Write-Host "Initialization of the AzLandingZone module in progress"
foreach($module in $moduleList){
	$mod = Get-Module -Name $module.Name
    if ($mod -ne $null -and $mod.Version -lt [System.Version]$module.Version) { 
        Write-Warning "This module requires $($module.Name) version $($module.Version). An earlier version of $($module.Name) is imported in the current PowerShell session. Please open a new session before importing this module. This error could indicate that multiple incompatible versions of the Azure PowerShell cmdlets are installed on your system." -ErrorAction Continue
    } 
    elseif ($mod -eq $null) { 
        Import-Module Az.Accounts -MinimumVersion $module.Version -Scope Global 
    }
}
Write-Host "Initialization of the AzLandingZone module completed"
