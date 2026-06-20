# Rotate Railway API token for Cursor MCP (no dashboard visit).
# Creates new token via Railway GraphQL, updates User env + mcp.secrets.env, revokes old cursor-mcp token if found.
$ErrorActionPreference = 'Stop'

$oldToken = [Environment]::GetEnvironmentVariable('RAILWAY_API_TOKEN', 'User')
if (-not $oldToken) { Write-Error 'RAILWAY_API_TOKEN not set in User env' }

$name = "cursor-mcp-rotated-$(Get-Date -Format yyyyMMdd-HHmm)"
$createBody = @{ query = "mutation { apiTokenCreate(input: { name: `"$name`" }) }" } | ConvertTo-Json
$headers = @{ Authorization = "Bearer $oldToken"; 'Content-Type' = 'application/json' }

$create = Invoke-RestMethod -Uri 'https://backboard.railway.com/graphql/v2' -Method Post -Headers $headers -Body $createBody
$newToken = $create.data.apiTokenCreate
if (-not $newToken) { throw "apiTokenCreate failed: $($create | ConvertTo-Json -Compress)" }

# Verify new token
$meBody = @{ query = '{ me { email } }' } | ConvertTo-Json
$me = Invoke-RestMethod -Uri 'https://backboard.railway.com/graphql/v2' -Method Post -Headers @{ Authorization = "Bearer $newToken"; 'Content-Type' = 'application/json' } -Body $meBody
Write-Host "[OK] New token works for $($me.data.me.email)"

# Find and delete prior cursor-mcp tokens (by name pattern)
$listBody = @{ query = '{ apiTokens { edges { node { id name } } } }' } | ConvertTo-Json
$list = Invoke-RestMethod -Uri 'https://backboard.railway.com/graphql/v2' -Method Post -Headers @{ Authorization = "Bearer $newToken"; 'Content-Type' = 'application/json' } -Body $listBody
foreach ($edge in $list.data.apiTokens.edges) {
  $node = $edge.node
  if ($node.name -match '^cursor-mcp' -and $node.name -ne $name) {
    $delBody = @{ query = "mutation { apiTokenDelete(id: `"$($node.id)`") }" } | ConvertTo-Json
    Invoke-RestMethod -Uri 'https://backboard.railway.com/graphql/v2' -Method Post -Headers @{ Authorization = "Bearer $newToken"; 'Content-Type' = 'application/json' } -Body $delBody | Out-Null
    Write-Host "[OK] Revoked old token: $($node.name)"
  }
}

[Environment]::SetEnvironmentVariable('RAILWAY_API_TOKEN', $newToken, 'User')
$secretsPath = Join-Path $env:USERPROFILE '.cursor\mcp.secrets.env'
"RAILWAY_API_TOKEN=$newToken" | Set-Content -Path $secretsPath -Encoding utf8
Write-Host "[OK] Updated User env and $secretsPath"
Write-Host "[ACTION] Restart Cursor so Railway MCP picks up the new token"
