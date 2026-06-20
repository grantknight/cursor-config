param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$AgentCmd = 'cursor-agent',
  [switch]$DryRun,
  [ValidateSet('top', 'mid', 'low', '')]
  [string]$DryRunFailTier = ''
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

$dataDir = Join-Path $RepoRoot 'data\autoresearch'
$verifyDir = Join-Path $RepoRoot 'scripts\verify'
New-Item -ItemType Directory -Force -Path $dataDir, $verifyDir | Out-Null

$questionsPath = Join-Path $dataDir 'examiner-questions.json'
$answersPath = Join-Path $dataDir 'examiner-answers.json'
$reportPath = Join-Path $dataDir 'examiner-report.json'
$programPath = Join-Path $dataDir 'program.md'
$checkScript = Join-Path $PSScriptRoot 'autoresearch-examiner-check.ps1'

$notify = Join-Path $env:USERPROFILE '.cursor\scripts\telegram-notify.ps1'
if (-not (Test-Path $notify)) {
  $notify = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\telegram-notify.ps1'
}

function Send-Tg([string]$Msg, [string]$Level) {
  if (Test-Path $notify) { & $notify -Message $Msg -Level $Level }
}

function Invoke-Agent([string]$Prompt) {
  if ($DryRun) { return "EXAMINER_TIER: PASS`n(dry run)" }
  if ($AgentCmd -eq 'cursor-agent') {
    $output = & cursor-agent -p $Prompt --force 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "cursor-agent exit $LASTEXITCODE" }
    return $output
  }
  $output = Invoke-Expression "$AgentCmd `"$($Prompt -replace '"','\"')`"" 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "agent exit $LASTEXITCODE" }
  return $output
}

function Parse-TierResult([string]$Output) {
  if ($Output -match 'EXAMINER_TIER:\s*PASS') { return @{ pass = $true; reason = 'PASS' } }
  if ($Output -match 'EXAMINER_TIER:\s*FAIL') {
    $reason = if ($Output -match 'TIER \w+:\s*(.+)') { $Matches[1].Trim() } else { 'FAIL' }
    return @{ pass = $false; reason = $reason }
  }
  return @{ pass = $false; reason = 'Missing EXAMINER_TIER marker in agent output' }
}

function Get-GoalFromProgram {
  if (-not (Test-Path $programPath)) { return 'See data/autoresearch/program.md' }
  $lines = Get-Content $programPath
  foreach ($line in $lines) {
    if ($line -match '^\s*Goal:\s*(.+)') { return $Matches[1].Trim() }
  }
  return (Get-Content $programPath -Raw).Substring(0, [Math]::Min(500, (Get-Content $programPath -Raw).Length))
}

$goal = Get-GoalFromProgram
$generatedAt = (Get-Date).ToUniversalTime().ToString('o')

# --- Phase 1: Plan (3 independent tier questions) ---
$tiers = @{}
foreach ($tier in @('top', 'mid', 'low')) {
  $agentFile = Join-Path $env:USERPROFILE ".cursor\agents\examiner-$tier.md"
  $planOut = Join-Path $verifyDir "examiner-plan-$tier.json"

  $planPrompt = @"
You are examiner-$tier (readonly). Read $agentFile and follow PLAN phase instructions.
Read $programPath for the goal.
Research independently. Write ONLY valid JSON to $planOut with keys: question, evidenceRequired, whatAgentsUsuallySkip.
Do not edit any other files. First line of your reply: EXAMINER_TIER: PASS
"@

  if ($DryRun) {
    $tierJson = @{
      question = "Dry-run $tier tier question for goal"
      evidenceRequired = 'file path or command output'
      whatAgentsUsuallySkip = 'dry run skip'
    } | ConvertTo-Json -Compress
    Set-Content -Path $planOut -Value $tierJson -Encoding UTF8
  }
  else {
    try { Invoke-Agent $planPrompt | Out-Null } catch { throw "Plan phase failed for tier $tier : $($_.Exception.Message)" }
    if (-not (Test-Path $planOut)) { throw "Plan phase did not write $planOut for tier $tier" }
  }

  $tiers[$tier] = Get-Content $planOut -Raw | ConvertFrom-Json
}

$questions = @{
  goal = $goal
  generatedAt = $generatedAt
  tiers = $tiers
}
($questions | ConvertTo-Json -Depth 6) | Set-Content -Path $questionsPath -Encoding UTF8

# --- Phase 2: Answer (implementer provides evidence) ---
$answerPrompt = @"
Read $programPath, $questionsPath. For each tier (top, mid, low), answer the examiner question with REAL evidence.
Write $answersPath as JSON:
{ "answeredAt": "ISO8601", "tiers": { "top": { "answer": "...", "evidence": "path/command/URL output", "status": "answered" }, ... } }
Run commands and cite actual output. If you cannot answer a tier, set status to "unable" (will FAIL).
Do not claim done. Only write the JSON file and stop.
"@

if ($DryRun) {
  $dryAnswers = @{
    answeredAt = $generatedAt
    tiers = @{
      top = @{ answer = 'dry run top answer'; evidence = 'README.md'; status = 'answered' }
      mid = @{ answer = 'dry run mid answer'; evidence = 'README.md'; status = 'answered' }
      low = @{ answer = 'dry run low answer'; evidence = 'README.md'; status = 'answered' }
    }
  }
  ($dryAnswers | ConvertTo-Json -Depth 6) | Set-Content -Path $answersPath -Encoding UTF8
}
else {
  try { Invoke-Agent $answerPrompt | Out-Null } catch { throw "Answer phase failed: $($_.Exception.Message)" }
  if (-not (Test-Path $answersPath)) { throw 'Answer phase did not write examiner-answers.json' }
}

# --- Phase 3: Grade (3 readonly examiners) ---
$reportTiers = @{}
$failedTiers = @()

foreach ($tier in @('top', 'mid', 'low')) {
  $agentFile = Join-Path $env:USERPROFILE ".cursor\agents\examiner-$tier.md"
  $gradePrompt = @"
You are examiner-$tier (readonly). Read $agentFile and follow GRADE phase instructions.
Read $questionsPath and $answersPath for tier $tier.
First line MUST be EXAMINER_TIER: PASS or EXAMINER_TIER: FAIL
Second line: TIER ${tier}: [reason with evidence]
Do not edit files.
"@

  if ($DryRun) {
    if ($DryRunFailTier -eq $tier) {
      $result = @{ pass = $false; reason = "intentional dry-run fail for tier $tier" }
    }
    else {
      $result = @{ pass = $true; reason = 'dry run pass' }
    }
  }
  else {
    $out = Invoke-Agent $gradePrompt
    $result = Parse-TierResult $out
  }

  $reportTiers[$tier] = $result
  if (-not $result.pass) { $failedTiers += $tier }
}

$report = @{
  gradedAt = (Get-Date).ToUniversalTime().ToString('o')
  tiers = $reportTiers
}
($report | ConvertTo-Json -Depth 6) | Set-Content -Path $reportPath -Encoding UTF8

# --- Phase 4: Mechanical check ---
& $checkScript -RepoRoot $RepoRoot
$checkExit = $LASTEXITCODE

if ($checkExit -eq 0) {
  Send-Tg "Examiner PASS: all tiers verified ($RepoRoot)" 'progress'
  exit 0
}

$failList = ($failedTiers -join ', ')
if ($failList) {
  Send-Tg "Examiner FAIL: tier(s) $failList - sent back to loop ($RepoRoot)" 'progress'
}
else {
  Send-Tg "Examiner FAIL: mechanical check ($RepoRoot)" 'progress'
}
exit 1
