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

if (-not (Test-Path $program)) {
  if (Test-Path $notify) {
    & $notify -Message "Autoresearch BLOCKED: missing data/autoresearch/program.md in $RepoRoot" -Level blocked
  }
  throw 'Missing data/autoresearch/program.md'
}

function Send-Tg([string]$Msg, [string]$Level) {
  if (Test-Path $notify) { & $notify -Message $Msg -Level $Level }
}

function Past-UntilHour([int]$Hour) {
  return (Get-Date).Hour -ge $Hour
}

$exp = 0
while ($exp -lt $MaxExperiments) {
  if (Past-UntilHour $UntilHour) {
    Send-Tg "Autoresearch stopped at $UntilHour`:00 ($RepoRoot)" 'progress'
    break
  }

  & $check
  if ($LASTEXITCODE -eq 0) {
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
    Invoke-Expression "$AgentCmd $prompt"
  }
  catch {
    Send-Tg "Autoresearch BLOCKED: agent failed — $($_.Exception.Message)" 'blocked'
    exit 2
  }

  $exp++
}

Send-Tg "Autoresearch ended after $exp experiments ($RepoRoot)" 'progress'
exit 1
