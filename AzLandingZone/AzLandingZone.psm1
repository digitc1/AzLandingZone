$moduleList = @(
	@{
		Name = 'Az.Accounts';
		Version = '2.10.3'
	}
	@{
		Name = 'Az.EventHub';
		Version = '3.1.0'
	}
	@{
		Name = 'Az.Resources';
		Version = '6.4.0'
	}
	@{
		Name = 'Az.Storage';
		Version = '5.1.0'
	}
)

Write-Host "Initialization of the AzLandingZone module in progress"
foreach($module in $moduleList){
	$mod = Get-Module -Name $module.Name
	if($null -eq $mod){
		if(Get-Module -ListAvailable -Name $module.Name){
			Uninstall-Module -Name $module.Name -AllVersions
		}
	} elseif ($mod.Version -lt [System.Version]$module.Version){
		Remove-Module -Name $module.Name
		Uninstall-Module -Name $module.Name -AllVersions
	}
	Install-Module $module.Name -requiredVersion $module.Version -Force
	Import-Module -Name $module.Name -RequiredVersion $module.Version -Force
}
Write-Host "Initialization of the AzLandingZone module completed"