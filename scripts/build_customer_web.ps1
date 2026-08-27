# Builds the customer marketplace (not the admin console) as a web preview
# and swaps in customer branding for the PWA shell.
#
#   powershell -ExecutionPolicy Bypass -File scripts\build_customer_web.ps1
#   firebase deploy --only hosting:qopcha-preview --project qopchaapp

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$outDir = 'build/web_customer'

flutter build web --release --dart-define=ADMIN_WEB=false --output $outDir
if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }

Copy-Item "$root\scripts\web_customer\index.html" "$root\$outDir\index.html" -Force
Copy-Item "$root\scripts\web_customer\manifest.json" "$root\$outDir\manifest.json" -Force

Write-Host "Customer web preview built at $outDir" -ForegroundColor Green
