# Regenerate ~/.cursor/mcp.secrets.env from Windows User env vars.
# Run after rotating GITHUB_TOKEN or RAILWAY_API_TOKEN, then restart Cursor.
$secretsPath = Join-Path $env:USERPROFILE '.cursor\mcp.secrets.env'
$rt = [Environment]::GetEnvironmentVariable('RAILWAY_API_TOKEN', 'User')
$gt = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN', 'User')
if (-not $rt) { throw 'RAILWAY_API_TOKEN missing in User env vars' }
if (-not $gt) { throw 'GITHUB_TOKEN missing in User env vars' }
@(
  "RAILWAY_API_TOKEN=$rt"
  "GITHUB_TOKEN=$gt"
) | Set-Content -Path $secretsPath -Encoding UTF8
Write-Host "Updated $secretsPath - restart Cursor to reload Railway MCP."
