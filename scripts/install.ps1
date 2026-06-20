param(
  [switch]$SkipSkills,
  [switch]$UpdateMcp
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$cursorHome = Join-Path $env:USERPROFILE '.cursor'

New-Item -ItemType Directory -Force -Path "$cursorHome\rules","$cursorHome\agents","$cursorHome\hooks","$cursorHome\skills","$cursorHome\docs","$cursorHome\templates\data\verify","$cursorHome\templates\scripts","$cursorHome\templates\autoresearch","$cursorHome\scripts" | Out-Null

Copy-Item "$repoRoot\rules\*" "$cursorHome\rules\" -Force
Copy-Item "$repoRoot\agents\*" "$cursorHome\agents\" -Force
Copy-Item "$repoRoot\hooks\stop-verify.js" "$cursorHome\hooks\stop-verify.js" -Force

$scriptNames = @(
  'telegram-notify.ps1',
  'sync-mcp-secrets.ps1',
  'rotate-railway-token.ps1',
  'autoresearch.ps1',
  'autoresearch-overnight.ps1',
  'autoresearch-check-targets.ps1',
  'autoresearch-examiner-gate.ps1',
  'autoresearch-examiner-check.ps1',
  'verify-all.ps1'
)
foreach ($name in $scriptNames) {
  $src = Join-Path $repoRoot "scripts\$name"
  if (Test-Path $src) {
    Copy-Item $src "$cursorHome\scripts\$name" -Force
  }
}

Copy-Item "$repoRoot\scripts\verify-all.ps1" "$cursorHome\templates\scripts\verify-all.ps1" -Force
Copy-Item "$repoRoot\templates\data\verify\targets.json" "$cursorHome\templates\data\verify\targets.json" -Force
Copy-Item "$repoRoot\docs\*.md" "$cursorHome\docs\" -Force

if (Test-Path "$repoRoot\templates\autoresearch") {
  Copy-Item "$repoRoot\templates\autoresearch\*" "$cursorHome\templates\autoresearch\" -Force
}

if (-not $SkipSkills) {
  Get-ChildItem "$repoRoot\skills" -Directory | ForEach-Object {
    $dest = Join-Path "$cursorHome\skills" $_.Name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $_.FullName $dest
  }
}

$mcpTemplate = Join-Path $repoRoot 'mcp.json.template'
$mcpDest = Join-Path $cursorHome 'mcp.json'
if (-not (Test-Path $mcpDest) -or $UpdateMcp) {
  Copy-Item $mcpTemplate $mcpDest -Force
  Write-Host "$(if ($UpdateMcp) { 'Updated' } else { 'Created' }) $mcpDest from template"
}

$hooksDest = Join-Path $cursorHome 'hooks.json'
@'
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": "node skills/impeccable/scripts/hook-before-edit.mjs",
        "timeout": 5
      }
    ],
    "stop": [
      {
        "command": "node hooks/stop-verify.js",
        "timeout": 300,
        "loop_limit": 10
      }
    ]
  }
}
'@ | Set-Content -Path $hooksDest -Encoding UTF8

$sync = Join-Path $cursorHome 'scripts\sync-mcp-secrets.ps1'
if (Test-Path $sync) {
  & $sync
}

Write-Host "Installed to $cursorHome"
Write-Host "Next: set User env vars (see scripts/secrets.template.ps1), restart Cursor"
