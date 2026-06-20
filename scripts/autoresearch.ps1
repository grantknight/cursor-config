param(
  [string]$RepoRoot = (Get-Location).Path
)

# Autoresearch entry point (= overnight loop). Includes examiner council by default.
# Loads Telegram secrets then runs autoresearch-overnight.ps1.

$secrets = Join-Path $env:USERPROFILE '.cursor-config-secrets.ps1'
if (Test-Path $secrets) { . $secrets }

Set-Location $RepoRoot
& "$PSScriptRoot\autoresearch-overnight.ps1" -RepoRoot $RepoRoot @args
