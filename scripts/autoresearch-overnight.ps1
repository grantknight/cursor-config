param(
  [string]$RepoRoot = (Get-Location).Path,
  [int]$UntilHour = 7,
  [int]$MaxExperiments = 50,
  [string]$AgentCmd = 'cursor-agent'
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoRoot

$check = Join-Path $RepoRoot 'scripts\autoresearch-check-targets.ps1'
$program = Join-Path $RepoRoot 'data\autoresearch\program.md'
$notify = Join-Path $env:USERPROFILE '.cursor\scripts\telegram-notify.ps1'
if (-not (Test-Path $notify)) {
  $notify = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\telegram-notify.ps1'
}

function Send-Tg([string]$Msg, [string]$Level) {
  if (-not (Test-Path $notify)) {
    throw "Telegram notify script missing: $notify"
  }
  & $notify -Message $Msg -Level $Level
}

function Get-StopAt([int]$Hour) {
  $now = Get-Date
  $stop = Get-Date -Hour $Hour -Minute 0 -Second 0
  if ($stop -le $now) { $stop = $stop.AddDays(1) }
  return $stop
}

try {
  Send-Tg "Autoresearch preflight OK ($RepoRoot)" 'progress'
}
catch {
  Write-Error "Autoresearch BLOCKED: Telegram preflight failed — $($_.Exception.Message)"
}

if (-not (Test-Path $program)) {
  Send-Tg "Autoresearch BLOCKED: missing data/autoresearch/program.md in $RepoRoot" 'blocked'
  throw 'Missing data/autoresearch/program.md'
}

$stopAt = Get-StopAt $UntilHour
$exp = 0
while ($exp -lt $MaxExperiments) {
  if ((Get-Date) -ge $stopAt) {
    Send-Tg "Autoresearch stopped at $($stopAt.ToString('yyyy-MM-dd HH:mm')) ($RepoRoot)" 'progress'
    break
  }

  try {
    & $check
    $checkExit = $LASTEXITCODE
  }
  catch {
    Send-Tg "Autoresearch BLOCKED: check failed — $($_.Exception.Message)" 'blocked'
    exit 2
  }

  if ($checkExit -eq 0) {
    Send-Tg "Autoresearch SUCCESS — all targets pass ($RepoRoot)" 'success'
    exit 0
  }

  $prompt = @"
Read $program. Run exactly ONE experiment:
1. Read last KEEP row in data/autoresearch/results.tsv
2. One change toward worst metric over targets.json (editable surface only)
3. Run harness from program.md
4. Append results.tsv row
5. KEEP (commit) or DISCARD (git reset)
STOP after one experiment. Do not ask questions.
"@

  try {
    if ($AgentCmd -eq 'cursor-agent') {
      & cursor-agent -p $prompt --force
      if ($LASTEXITCODE -ne 0) {
        Send-Tg "Autoresearch BLOCKED: cursor-agent exit $LASTEXITCODE ($RepoRoot)" 'blocked'
        exit 2
      }
    }
    else {
      Invoke-Expression "$AgentCmd `"$($prompt -replace '"','\"')`""
      if ($LASTEXITCODE -ne 0) {
        Send-Tg "Autoresearch BLOCKED: agent exit $LASTEXITCODE ($RepoRoot)" 'blocked'
        exit 2
      }
    }
  }
  catch {
    Send-Tg "Autoresearch BLOCKED: agent failed — $($_.Exception.Message)" 'blocked'
    exit 2
  }

  $exp++
}

Send-Tg "Autoresearch ended after $exp experiments ($RepoRoot)" 'progress'
exit 1
