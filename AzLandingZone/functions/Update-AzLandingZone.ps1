Function Update-AzLandingZone {
    $name = "lzslz"
    setup-Resources -Name $name
    setup-Policy -Name $name
}
Export-ModuleMember -Function Update-AzLandingZone