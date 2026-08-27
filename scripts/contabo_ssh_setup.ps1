# Quick deploy helpers (Windows)

## Generate SSH key for Contabo
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\qopcha_contabo" -N '""'
Write-Host "`nAdd this PUBLIC key to the VPS ~/.ssh/authorized_keys:`n"
Get-Content "$env:USERPROFILE\.ssh\qopcha_contabo.pub"

## Test API on VPS
# ssh -i $env:USERPROFILE\.ssh\qopcha_contabo root@169.58.230.144 "curl -s http://127.0.0.1:8080/api/health"

## Trigger remote update
# ssh -i $env:USERPROFILE\.ssh\qopcha_contabo root@169.58.230.144 "bash /opt/qopcha-api/update.sh"

## Seed products on public API
# node server/scripts/seed_demo.js http://169.58.230.144
