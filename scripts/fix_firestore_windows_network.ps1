# Run in an elevated PowerShell: Right-click → Run as administrator
# Fixes common Windows causes of Firebase WatchStream "No route to host".

$ErrorActionPreference = 'Stop'

Write-Host '1) Prefer IPv4 over IPv6 for dual-stack apps (gRPC/Firestore)...'
netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 55 4 | Out-Null

Write-Host '2) Set reliable DNS on Wi-Fi...'
try {
  Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses '8.8.8.8','1.1.1.1'
} catch {
  Write-Warning "Could not set Wi-Fi DNS: $_"
}

$exe = Join-Path $PSScriptRoot '..\build\windows\x64\runner\Debug\qopcha.exe' | Resolve-Path -ErrorAction SilentlyContinue
if ($exe) {
  Write-Host "3) Allow outbound firewall for $exe ..."
  netsh advfirewall firewall delete rule name='Qopcha Flutter Outbound' | Out-Null
  netsh advfirewall firewall add rule name='Qopcha Flutter Outbound' dir=out action=allow program="$exe" enable=yes profile=any | Out-Null
} else {
  Write-Warning 'qopcha.exe not built yet — skip firewall rule. Rebuild, then re-run this script.'
}

Write-Host ''
Write-Host 'Done. Disconnect OpenVPN if it is connected, then:'
Write-Host '  flutter run -d windows'
Write-Host ''
Write-Host 'Verify: Test-NetConnection firestore.googleapis.com -Port 443'
