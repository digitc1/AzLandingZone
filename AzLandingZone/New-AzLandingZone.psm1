if(!(Get-Module AzSentinel)){
	Install-Module -Force -Name "AzSentinel" -RequiredVersion "0.6.3"
	Import-Module AzSentinel
}
if(!(Get-Module Az.Security)){
	Install-Module -Force -Name "Az.Security" -RequiredVersion "0.7.8"
	Import-Module Az.Security
}
if(!(Get-Module Az.Automation)){
	Install-Module -Force -Name "Az.Automation" -RequiredVersion "1.3.6"
	Import-Module Az.Automation
}