try {
    $DHCP = Get-DhcpServerInDC
}
catch {
    $DHCP = $null
    Write-Host "False"
    Ninja-Property-Set isdhcpserver "False"
}

$DNSName = ([system.net.dns]::GetHostByName("localhost")).hostname

if ($DNSName -in $DHCP.DnsName){
    Write-Host "True"
    Ninja-Property-Set isdhcpserver "True"
}