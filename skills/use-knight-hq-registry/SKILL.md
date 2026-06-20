---
name: use-knight-hq-registry
description: >-
  Read grantknight/knight-hq-registry before DNS, Railway, subdomain, or
  cross-project infra work. Use when adding domains, checking what's deployed,
  or mapping Telegram topics and Cloudflare zones.
---

# Knight HQ Registry

## When to use

- Before creating or changing DNS records
- Before adding Railway custom domains or new services
- When unsure which repo owns a subdomain or URL
- When wiring Telegram notifications to the right forum topic

## Source of truth

Repo: **grantknight/knight-hq-registry**  
Local clone: `~/Desktop/Projects/knight-hq-registry`

| File | Read for |
|------|----------|
| `registry/projects.yaml` | App list, URLs, GitHub, local paths |
| `registry/domains.yaml` | Zones, used/reserved subdomains |
| `registry/railway.yaml` | Railway project → service → domain |
| `registry/integrations.yaml` | Telegram topics, Cloudflare zone IDs |
| `projects/*.md` | One-page per-app summary |

## Workflow

1. Read relevant YAML before any infra change
2. Check `domains.yaml` for collisions (used vs available subdomains)
3. Check `railway.yaml` for existing services in the same project
4. After a confirmed change, update the registry in the same PR/session

## Telegram (Cursor)

- Chat: Knight HQ (`TELEGRAM_CHAT_ID`)
- Cursor forum topic: **508** (`TELEGRAM_TOPIC_ID`)
- Script: `cursor-config/scripts/telegram-notify.ps1`

## Validate

```powershell
cd ~/Desktop/Projects/knight-hq-registry
.\scripts\validate-registry.ps1
```

Use `-SkipHttp` for file-only validation.

## Never store here

API tokens, bot tokens, database URLs, or `.env` contents.
