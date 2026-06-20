param(
  [switch]$SkipSkills
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$cursorHome = Join-Path $env:USERPROFILE '.cursor'

New-Item -ItemType Directory -Force -Path "$cursorHome\rules","$cursorHome\agents","$cursorHome\hooks","$cursorHome\skills","$cursorHome\docs","$cursorHome\templates\data\verify","$cursorHome\templates\scripts","$cursorHome\scripts" | Out-Null

Copy-Item "$repoRoot\rules\*" "$cursorHome\rules\" -Force
Copy-Item "$repoRoot\agents\*" "$cursorHome\agents\" -Force
Copy-Item "$repoRoot\hooks\stop-verify.js" "$cursorHome\hooks\stop-verify.js" -Force
Copy-Item "$repoRoot\scripts\telegram-notify.ps1" "$cursorHome\scripts\telegram-notify.ps1" -Force
Copy-Item "$repoRoot\scripts\verify-all.ps1" "$cursorHome\templates\scripts\verify-all.ps1" -Force
Copy-Item "$repoRoot\templates\data\verify\targets.json" "$cursorHome\templates\data\verify\targets.json" -Force
Copy-Item "$repoRoot\docs\*.md" "$cursorHome\docs\" -Force

if (-not $SkipSkills) {
  Get-ChildItem "$repoRoot\skills" -Directory | ForEach-Object {
    $dest = Join-Path "$cursorHome\skills" $_.Name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse -Force $_.FullName $dest
  }
}

$mcpTemplate = Join-Path $repoRoot 'mcp.json.template'
$mcpDest = Join-Path $cursorHome 'mcp.json'
if (-not (Test-Path $mcpDest)) {
  Copy-Item $mcpTemplate $mcpDest -Force
  Write-Host "Created $mcpDest from template (review paths before restart)"
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

Write-Host "Installed to $cursorHome"
Write-Host "Next: set User env vars (see scripts/secrets.template.ps1), run sync-mcp-secrets.ps1, restart Cursor"
