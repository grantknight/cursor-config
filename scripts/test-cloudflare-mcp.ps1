# Quick health check - zone DNS tokens return 401 on /user/tokens/verify but work for MCP.
$ErrorActionPreference = 'Stop'
$token = [Environment]::GetEnvironmentVariable('CLOUDFLARE_API_TOKEN', 'User')
if (-not $token) { throw 'CLOUDFLARE_API_TOKEN not set in User env' }

$zones = Invoke-RestMethod -Uri 'https://api.cloudflare.com/client/v4/zones?per_page=10' -Headers @{ Authorization = "Bearer $token" }
if (-not $zones.success) { throw "Cloudflare zones API failed: $($zones | ConvertTo-Json -Compress)" }

Write-Host "[OK] Cloudflare token works - $($zones.result.Count) zone(s):"
$zones.result | ForEach-Object { Write-Host "  - $($_.name) ($($_.id))" }

try {
  Invoke-RestMethod -Uri 'https://api.cloudflare.com/client/v4/user/tokens/verify' -Headers @{ Authorization = "Bearer $token" } | Out-Null
  Write-Host '[OK] /user/tokens/verify also passed'
}
catch {
  Write-Host '[INFO] /user/tokens/verify returns 401 for zone-scoped DNS tokens - expected; MCP still works'
}

Write-Host '[ACTION] If cloudflare MCP is red in Cursor: Clear All MCP Tokens, restart Cursor, do not click OAuth'
