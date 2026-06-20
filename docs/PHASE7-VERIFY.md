# Phase 7 — Verification Checklist

Run date: 2026-06-20

## MCP stack

| Check | Result |
|-------|--------|
| GitHub MCP / `gh auth status` | PASS — logged in as grantknight |
| Railway MCP `list_projects` | PASS — 7 projects listed |
| Cloudflare MCP `execute` DNS lookup | PASS — ada.dragonflight.co.za → ada-helipads-production.up.railway.app |
| Playwright MCP | PASS — screenshot ada health (phase7-ada-health.png) |

## Live endpoints

| URL | Result |
|-----|--------|
| https://ada.dragonflight.co.za/health | HTTP 200 |
| cursor-ide-browser navigate | PASS — JSON health page loaded |

## Skills & rules

| Item | Result |
|------|--------|
| ponytail.mdc (alwaysApply) | PASS |
| 15-check-registry-before-infra.mdc | PASS (Phase 5C) |
| use-knight-hq-registry skill | PASS |
| Impeccable context.mjs | PASS (NO_PRODUCT_MD on cursor-template) |

## Telegram (Knight HQ → Cursor topic)

| Item | Value |
|------|-------|
| Chat | Knight HQ (`TELEGRAM_CHAT_ID`) |
| Forum topic | **Cursor** |
| Thread ID | **508** (`TELEGRAM_TOPIC_ID`) |
| Test | PASS — message via `telegram-notify.ps1` to topic 508 |

## Registry (Phase 5C)

| Item | Result |
|------|--------|
| Repo | grantknight/knight-hq-registry |
| validate-registry.ps1 (files) | PASS |
| integrations.yaml Cursor topic | 508 documented |

## Optional (not run)

- Stop-hook fail/retry demo — harness documented in VERIFICATION-GATE.md; manual trigger only

## Proof commands

```powershell
gh auth status
railway list
Invoke-WebRequest https://ada.dragonflight.co.za/health -UseBasicParsing
& "$env:USERPROFILE\Desktop\Projects\cursor-config\scripts\telegram-notify.ps1" -Message "Phase 7 verify" -Level success
& "$env:USERPROFILE\Desktop\Projects\knight-hq-registry\scripts\validate-registry.ps1" -SkipHttp
```

Restart Cursor after env var changes so MCP picks up secrets.
