# Overnight autoresearch + Telegram

## Per-project setup

```powershell
mkdir data\autoresearch, scripts\verify -Force
Copy-Item "$env:USERPROFILE\.cursor\templates\scripts\verify-all.ps1" scripts\
Copy-Item cursor-config\templates\data\verify\targets.json data\verify\
Copy-Item cursor-config\templates\autoresearch\program.md.template data\autoresearch\program.md
Copy-Item cursor-config\templates\autoresearch\targets.json.template data\autoresearch\targets.json
Copy-Item cursor-config\scripts\autoresearch*.ps1 scripts\
echo commit	metric	status	notes > data\autoresearch\results.tsv
```

Edit `program.md` and `targets.json` for the repo.

## Run

```powershell
.\scripts\autoresearch.ps1
```

Or from cursor-config scripts copied into project:

```powershell
.\scripts\autoresearch-overnight.ps1 -RepoRoot .
```

## Loop behavior

1. Headless agent runs ONE experiment (`cursor-agent` or Cursor Automation)
2. `autoresearch-check-targets.ps1` runs frozen `verify-all.ps1`
3. If `examinerRequired: true`, `autoresearch-examiner-gate.ps1` runs (top/mid/low council)
4. All pass → Telegram SUCCESS → stop
5. Examiner FAIL → agent fixes gaps, loop continues (max `examinerMaxRetries`)
6. Harness fail → next experiment (no user ping)
7. Harness broken / missing secrets → Telegram BLOCKED
8. Stop at 07:00 local or max experiments

## Telegram secrets

Windows User env vars (or `~/.cursor-config-secrets.ps1`):

| Var | Value |
|-----|-------|
| `TELEGRAM_BOT_TOKEN` | @KnightHQ_bot token |
| `TELEGRAM_CHAT_ID` | `-1004292432894` (Knight HQ group) |
| `TELEGRAM_TOPIC_ID` | `508` — Cursor forum topic (outbound alerts only; Maverick ignores inbound) |

Test:

```powershell
.\scripts\telegram-notify.ps1 -Message "Cursor overnight test" -Level info
```

## Model

Recommended: Cursor subscription + `cursor-agent` (no Z.ai in mcp.json).
