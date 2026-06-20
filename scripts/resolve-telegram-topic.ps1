param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$ProjectKey,
  [switch]$List
)

$ErrorActionPreference = 'Stop'

$registryRoot = Join-Path $env:USERPROFILE 'Desktop\Projects\knight-hq-registry'
$cursorMapLocal = Join-Path $registryRoot 'registry\cursor-telegram-topics.json'
$targetsPath = Join-Path $RepoRoot 'data\autoresearch\targets.json'

function Get-Targets {
  if (-not (Test-Path $targetsPath)) { return $null }
  return Get-Content $targetsPath -Raw | ConvertFrom-Json
}

function Get-CursorMap {
  if (Test-Path $cursorMapLocal) {
    return Get-Content $cursorMapLocal -Raw | ConvertFrom-Json
  }
  return $null
}

function Resolve-KeyFromPath([string]$Root) {
  if (-not (Test-Path $Root)) { return $null }
  $norm = (Resolve-Path -LiteralPath $Root).Path.ToLower()
  $map = Get-CursorMap
  if ($map -and $map.projects) {
    foreach ($p in $map.projects) {
      if ($p.localPath) {
        $lp = ($p.localPath -replace '~', $env:USERPROFILE).TrimEnd('\')
        if ($norm -eq $lp.ToLower()) { return $p.key }
      }
    }
  }
  $name = Split-Path $Root -Leaf
  switch -Regex ($name.ToLower()) {
    'ada-helipads' { return 'ada-helipads' }
    'ada-roster' { return 'ada-roster' }
    'dragonflight' { return 'dragonflight-website' }
    'logbook' { return 'logbook' }
    '^sop$' { return 'sop-aero' }
    'paperclip' { return 'paperclip' }
    'cursor-config' { return 'cursor-config' }
    'cursor-template' { return 'cursor-template' }
    'quoteconnect' { return 'quoteconnect' }
    default { return $null }
  }
}

$map = Get-CursorMap
if ($List) {
  if (-not $map) {
    Write-Host 'No cursor-telegram-topics.json - run Sync-KnightHqTelegramLayout.ps1 first'
    exit 1
  }
  $map.projects | ForEach-Object { Write-Host "$($_.key)`t$($_.threadId)`t$($_.name)" }
  exit 0
}

$key = $ProjectKey
if (-not $key) {
  $targets = Get-Targets
  if ($targets -and $targets.telegramProjectKey) { $key = $targets.telegramProjectKey }
}
if (-not $key) { $key = Resolve-KeyFromPath $RepoRoot }

$threadId = $null
$targets = Get-Targets
if ($targets -and $targets.telegramTopicId) {
  $threadId = [int]$targets.telegramTopicId
}

if (-not $threadId -and $map) {
  if ($key) {
    $proj = $map.projects | Where-Object { $_.key -eq $key } | Select-Object -First 1
    if ($proj) { $threadId = [int]$proj.threadId }
  }
  if (-not $threadId -and $map.headingThreadId) {
    $threadId = [int]$map.headingThreadId
  }
}

if (-not $threadId) {
  $fallback = [Environment]::GetEnvironmentVariable('TELEGRAM_TOPIC_ID', 'User')
  if ($fallback) { $threadId = [int]$fallback }
}

if (-not $threadId) {
  throw "Could not resolve Telegram topic for $RepoRoot key=$key"
}

Write-Output $threadId
