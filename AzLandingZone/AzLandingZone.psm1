if(!(Get-Module Az.Security)){
	Install-Module -Force -Name "Az.Security" -RequiredVersion "0.8.0"
	Import-Module Az.Security
}
if(!(Get-Module Az.Automation)){
	Install-Module -Force -Name "Az.Automation" -RequiredVersion "1.4.0"
	Import-Module Az.Automation
}