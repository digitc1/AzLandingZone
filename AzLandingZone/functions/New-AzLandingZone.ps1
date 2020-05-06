Function New-AzLandingZone {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $name
        [ValidateSet("DIGIT", "CERTEU", "None")]
        [string] $SOC
        [Parameter(Mandatory=$true)]
        [bool] $autoupdate
    )

    Write-Host "The parameters are as follow"
    Write-Host "Name= $name"
    Write-Host "SOC= $SOC"
    Write-Host "auto-update= $autoupdate"
}
Export-ModuleMember -Function New-AzLandingZone