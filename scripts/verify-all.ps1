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

function Invoke-Native {
  param(
    [string]$Name,
    [string]$CommandLine
  )
  Write-Log "STEP: $Name"
  cmd /c "$CommandLine 2>&1" | ForEach-Object { Write-Log $_ }
  if ($LASTEXITCODE -ne 0) {
    Write-Log "FAIL: $Name - exit code $LASTEXITCODE"
    return $false
  }
  Write-Log "OK: $Name"
  return $true
}

$targets = @{
  buildPasses       = $false
  testsPass         = $false
  typecheck         = $false
  healthUrl         = $null
  visualRequired    = $false
  slopCheckRequired = $false
  screenshotUrl     = $null
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
$hasPkg = Test-Path $pkgPath

if ($hasPkg) {
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  $scripts = $pkg.scripts

  if ($targets.typecheck) {
    if ($scripts.PSObject.Properties['typecheck']) {
      if (-not (Invoke-Native 'npm run typecheck' 'npm run typecheck')) { $allOk = $false }
    }
    elseif (Test-Path (Join-Path $root 'tsconfig.json')) {
      if (-not (Invoke-Native 'tsc --noEmit' 'npx tsc --noEmit')) { $allOk = $false }
    }
    else {
      Write-Log 'FAIL: typecheck required but no npm run typecheck or tsconfig.json'
      $allOk = $false
    }
  }

  if ($targets.buildPasses) {
    if ($scripts.PSObject.Properties['build']) {
      if (-not (Invoke-Native 'npm run build' 'npm run build')) { $allOk = $false }
    }
    else {
      Write-Log 'FAIL: buildPasses required but package.json has no build script'
      $allOk = $false
    }
  }

  if ($targets.testsPass) {
    if ($scripts.PSObject.Properties['test']) {
      if (-not (Invoke-Native 'npm test' 'npm test')) { $allOk = $false }
    }
    else {
      Write-Log 'FAIL: testsPass required but package.json has no test script'
      $allOk = $false
    }
  }
}
else {
  foreach ($flag in @('buildPasses', 'testsPass', 'typecheck')) {
    if ($targets[$flag]) {
      Write-Log "FAIL: $flag required but no package.json in project root"
      $allOk = $false
    }
  }
  if (-not ($targets.buildPasses -or $targets.testsPass -or $targets.typecheck -or $targets.healthUrl -or $targets.visualRequired -or $targets.slopCheckRequired)) {
    Write-Log 'SKIP: no package.json (harness-only project - all build/test flags off)'
  }
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
    $ok = Invoke-Native "screenshot $shotUrl" "npx playwright screenshot `"$shotUrl`" --viewport-size 1440,900 `"$png`""
    if (-not $ok) { $allOk = $false }
    elseif (-not (Test-Path $png)) {
      Write-Log 'FAIL: screenshot file missing after playwright'
      $allOk = $false
    }
  }
  else {
    Write-Log 'FAIL: visualRequired true but no screenshotUrl or healthUrl in targets.json'
    $allOk = $false
  }
}

if ($targets.slopCheckRequired) {
  $detect = Join-Path $env:USERPROFILE '.cursor\skills\impeccable\scripts\detect.mjs'
  if (-not (Test-Path $detect)) {
    Write-Log 'FAIL: slopCheckRequired but impeccable detect.mjs not installed'
    $allOk = $false
  }
  else {
    $ok = Invoke-Native 'impeccable detect' "node `"$detect`""
    if (-not $ok) { $allOk = $false }
  }
}

if ($allOk) {
  Write-Log 'RESULT: PASS (harness only - council subagents still required before user-facing done)'
  Write-Log "Log file: $logFile"
  exit 0
}

Write-Log 'RESULT: FAIL'
Write-Log "Log file: $logFile"
exit 1
