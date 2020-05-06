Function Update-AzLandingZone {
    $name = "lzslz"
    setup-Resources -Name $name
    setup-policy -Name $name
}
Export-ModuleMember -Function Update-AzLandingZone