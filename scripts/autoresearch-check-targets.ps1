param(
  [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

$verify = Join-Path $RepoRoot 'scripts\verify-all.ps1'
if (-not (Test-Path $verify)) {
  Write-Error "Missing frozen harness: scripts/verify-all.ps1"
}

& $verify
if ($LASTEXITCODE -ne 0) {
  Write-Host 'CHECK: FAIL (verify-all)'
  exit 1
}

$targetsPath = Join-Path $RepoRoot 'data\autoresearch\targets.json'
if (-not (Test-Path $targetsPath)) {
  Write-Host 'CHECK: PASS (no targets.json — verify-all only)'
  exit 0
}

$targets = Get-Content $targetsPath -Raw | ConvertFrom-Json
$resultsPath = Join-Path $RepoRoot 'data\autoresearch\results.tsv'
if (-not (Test-Path $resultsPath)) {
  Write-Host 'CHECK: FAIL (no results.tsv)'
  exit 1
}

$lines = Get-Content $resultsPath | Where-Object { $_ -and $_ -notmatch '^#' -and $_ -notmatch '^commit\t' }
if ($lines.Count -lt 1) {
  Write-Host 'CHECK: FAIL (results.tsv has no experiments)'
  exit 1
}

$keepLines = @()
foreach ($line in $lines) {
  $cols = $line -split "`t"
  if ($cols.Count -ge 3 -and $cols[2] -eq 'KEEP') {
    $keepLines += ,$line
  }
}

if ($keepLines.Count -lt 1) {
  Write-Host 'CHECK: FAIL (no KEEP rows in results.tsv)'
  exit 1
}

$last = ($keepLines | Select-Object -Last 1) -split "`t"
if ($last.Count -lt 2) {
  Write-Host 'CHECK: FAIL (KEEP row malformed)'
  exit 1
}

$metricVal = [double]$last[1]
foreach ($prop in $targets.PSObject.Properties) {
  $limit = [double]$prop.Value
  if ($metricVal -gt $limit) {
    Write-Host "CHECK: FAIL ($($prop.Name) $metricVal > $limit)"
    exit 1
  }
}

Write-Host 'CHECK: PASS (all targets within budget on last KEEP row)'
exit 0
