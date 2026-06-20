param(
  [string]$RepoRoot = (Get-Location).Path
)

$secrets = Join-Path $env:USERPROFILE '.cursor-config-secrets.ps1'
if (Test-Path $secrets) { . $secrets }

Set-Location $RepoRoot
& "$PSScriptRoot\autoresearch-overnight.ps1" -RepoRoot $RepoRoot @args
