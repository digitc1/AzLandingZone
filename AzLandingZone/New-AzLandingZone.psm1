$module = Get-Module Az.Accounts 
if ($module -ne $null -and $module.Version.ToString().CompareTo("1.9.0") -lt 0) 
{
	Update-Module -Name Az.Accounts -RequiredVersion "1.9.0" -Force
} 
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