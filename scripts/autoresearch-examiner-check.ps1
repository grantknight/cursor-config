# FROZEN - Examiner council mechanical check.
# Agents must NOT edit this file during autoresearch loops.
param(
  [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

$reportPath = Join-Path $RepoRoot 'data\autoresearch\examiner-report.json'
$questionsPath = Join-Path $RepoRoot 'data\autoresearch\examiner-questions.json'
$answersPath = Join-Path $RepoRoot 'data\autoresearch\examiner-answers.json'

function Fail([string]$Msg) {
  Write-Host "EXAMINER_VERIFY: FAIL"
  Write-Host $Msg
  exit 1
}

foreach ($p in @($reportPath, $questionsPath, $answersPath)) {
  if (-not (Test-Path $p)) { Fail "Missing $p" }
}

try {
  $report = Get-Content $reportPath -Raw | ConvertFrom-Json
  $questions = Get-Content $questionsPath -Raw | ConvertFrom-Json
  $answers = Get-Content $answersPath -Raw | ConvertFrom-Json
}
catch {
  Fail "Invalid JSON: $($_.Exception.Message)"
}

foreach ($tier in @('top', 'mid', 'low')) {
  $q = $questions.tiers.$tier
  if (-not $q -or -not $q.question) { Fail "Missing question for tier $tier" }
  $a = $answers.tiers.$tier
  if (-not $a -or -not $a.answer) { Fail "Missing answer for tier $tier" }
  if ($a.status -eq 'unable') { Fail "Tier $tier marked unable" }
  $r = $report.tiers.$tier
  if (-not $r) { Fail "Missing report for tier $tier" }
  if ($r.pass -ne $true) {
    Fail "Tier $tier not pass: $($r.reason)"
  }
}

Write-Host 'EXAMINER_VERIFY: PASS'
Write-Host 'All tiers (top, mid, low) passed examiner council'
exit 0
