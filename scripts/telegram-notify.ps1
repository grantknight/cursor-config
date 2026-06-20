param(
  [Parameter(Mandatory = $true)][string]$Message,
  [ValidateSet('info', 'success', 'blocked', 'progress')][string]$Level = 'info',
  [string]$ChatId,
  [string]$TopicId
)

$ErrorActionPreference = 'Stop'

function Get-Secret([string]$Name) {
  $v = [Environment]::GetEnvironmentVariable($Name, 'User')
  if ($v) { return $v }
  $secrets = Join-Path $env:USERPROFILE '.cursor-config-secrets.ps1'
  if (Test-Path $secrets) {
    . $secrets
    $fromFile = Get-Variable -Name $Name -ValueOnly -ErrorAction SilentlyContinue
    if ($fromFile) { return [string]$fromFile }
  }
  return $null
}

$token = Get-Secret 'TELEGRAM_BOT_TOKEN'
$chat = if ($ChatId) { $ChatId } else { Get-Secret 'TELEGRAM_CHAT_ID' }
$topic = if ($TopicId) { $TopicId } else { Get-Secret 'TELEGRAM_TOPIC_ID' }

if (-not $token -or -not $chat) {
  Write-Error 'Missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID (User env or ~/.cursor-config-secrets.ps1)'
}

$prefix = switch ($Level) {
  'success' { '[OK]' }
  'blocked' { '[BLOCKED]' }
  'progress' { '[...]' }
  default { '[info]' }
}

$body = @{
  chat_id = $chat
  text = "$prefix $Message"
  disable_web_page_preview = $true
}
if ($topic) { $body.message_thread_id = [int]$topic }

$json = $body | ConvertTo-Json -Compress
$uri = "https://api.telegram.org/bot$token/sendMessage"
$response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $json
if (-not $response.ok) { throw "Telegram API error: $($response | ConvertTo-Json -Compress)" }
Write-Host "Telegram sent (message_id=$($response.result.message_id))"
