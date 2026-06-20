# FROZEN - Grant Verification Gate harness.
# Agents must NOT edit this file. Change data/verify/targets.json instead.
param(
  [switch]$SkipVisual
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$verifyDir = Join-Path $root 'scripts/verify'
New-Item -ItemType Directory -Force -Path $verifyDir | Out-Null
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = Join-Path $verifyDir "gate-$ts.log"

function Write-Log {
  param([string]$Message)
  $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
  Write-Host $line
  Add-Content -Path $logFile -Value $line
}

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Block
  )
  Write-Log "STEP: $Name"
  try {
    & $Block
    Write-Log "OK: $Name"
    return $true
  }
  catch {
    Write-Log "FAIL: $Name - $($_.Exception.Message)"
    return $false
  }
}

$targets = @{
  buildPasses     = $true
  testsPass       = $true
  typecheck       = $true
  healthUrl       = $null
  visualRequired  = $true
  slopCheckRequired = $true
  screenshotUrl   = $null
}

$targetsPath = Join-Path $root 'data/verify/targets.json'
if (Test-Path $targetsPath) {
  $loaded = Get-Content $targetsPath -Raw | ConvertFrom-Json
  foreach ($prop in $loaded.PSObject.Properties) {
    $targets[$prop.Name] = $prop.Value
  }
}

$allOk = $true
$pkgPath = Join-Path $root 'package.json'

if (Test-Path $pkgPath) {
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  $scripts = $pkg.scripts

  if ($targets.typecheck -and $scripts.PSObject.Properties['typecheck']) {
    $ok = Invoke-Step 'npm run typecheck' {
      npm run typecheck 2>&1 | ForEach-Object { Write-Log $_ }
      if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    }
    if (-not $ok) { $allOk = $false }
  }
  elseif ($targets.typecheck -and (Test-Path (Join-Path $root 'tsconfig.json'))) {
    $ok = Invoke-Step 'tsc --noEmit' {
      npx tsc --noEmit 2>&1 | ForEach-Object { Write-Log $_ }
      if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    }
    if (-not $ok) { $allOk = $false }
  }

  if ($targets.buildPasses -and $scripts.PSObject.Properties['build']) {
    $ok = Invoke-Step 'npm run build' {
      npm run build 2>&1 | ForEach-Object { Write-Log $_ }
      if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    }
    if (-not $ok) { $allOk = $false }
  }

  if ($targets.testsPass -and $scripts.PSObject.Properties['test']) {
    $ok = Invoke-Step 'npm test' {
      npm test 2>&1 | ForEach-Object { Write-Log $_ }
      if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    }
    if (-not $ok) { $allOk = $false }
  }
}
else {
  Write-Log 'SKIP: no package.json (nothing to build/test)'
}

if ($targets.healthUrl) {
  $url = [string]$targets.healthUrl
  $ok = Invoke-Step "health $url" {
    $code = curl.exe -sS -o NUL -w '%{http_code}' $url
    Write-Log "HTTP $code"
    if ($code -notmatch '^2') { throw "health check HTTP $code" }
  }
  if (-not $ok) { $allOk = $false }
}

$wantVisual = $targets.visualRequired -and -not $SkipVisual
if ($wantVisual) {
  $shotUrl = $targets.screenshotUrl
  if (-not $shotUrl -and $targets.healthUrl) {
    $shotUrl = $targets.healthUrl
  }
  if ($shotUrl) {
    $png = Join-Path $verifyDir "gate-$ts.png"
    $ok = Invoke-Step "screenshot $shotUrl" {
      npx playwright screenshot $shotUrl --viewport-size 1440,900 $png 2>&1 | ForEach-Object { Write-Log $_ }
      if ($LASTEXITCODE -ne 0) { throw 'playwright screenshot failed' }
      if (-not (Test-Path $png)) { throw 'screenshot file missing' }
    }
    if (-not $ok) { $allOk = $false }
  }
  else {
    Write-Log 'SKIP: visual (set screenshotUrl or healthUrl in targets.json)'
  }
}

if ($allOk) {
  Write-Log 'RESULT: PASS'
  Write-Log "Log file: $logFile"
  exit 0
}

Write-Log 'RESULT: FAIL'
Write-Log "Log file: $logFile"
exit 1
