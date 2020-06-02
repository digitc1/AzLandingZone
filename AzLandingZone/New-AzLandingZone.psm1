if(!(Get-Module AzSentinel)){
	Install-Module -Force -Name "AzSentinel"
	Import-Module AzSentinel
}
if(!(Get-Module Az.Security)){
	Install-Module -Force -Name "Az.Security"
	Import-Module Az.Security
}
if(!(Get-Module Az.Automation)){
	Install-Module -Force -Name "Az.Automation"
	Import-Module Az.Automation
}