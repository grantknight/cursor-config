# cursor-config

Grant Knight Cursor user-level setup: MCP templates, rules, council verifiers, verification gate, overnight autoresearch + Telegram.

## Install (one-liner)

```powershell
git clone https://github.com/grantknight/cursor-config.git
cd cursor-config
.\scripts\install.ps1
```

Then set secrets (`scripts\secrets.template.ps1`), run `scripts\sync-mcp-secrets.ps1`, fully restart Cursor.

## What's included

| Path | Purpose |
|------|---------|
| `rules/` | Autonomy, infra, design, verify-before-done, Ponytail, stop-slop |
| `agents/` | code-verifier, visual-verifier, slop-auditor |
| `hooks/stop-verify.js` | Ralph loop on verify-all failure |
| `skills/` | Ponytail, Impeccable, autoresearch, task-completion, etc. |
| `scripts/verify-all.ps1` | Frozen per-project harness template |
| `scripts/telegram-notify.ps1` | Knight HQ Telegram alerts |
| `scripts/autoresearch*.ps1` | Overnight loop drivers |
| `docs/` | MCP, DNS, verification gate, overnight |

## Bootstrap a project

```powershell
mkdir scripts, scripts\verify, data\verify, data\autoresearch -Force
Copy-Item "$env:USERPROFILE\.cursor\templates\scripts\verify-all.ps1" scripts\
Copy-Item templates\data\verify\targets.json data\verify\
Copy-Item templates\autoresearch\program.md.template data\autoresearch\program.md
Copy-Item templates\autoresearch\targets.json.template data\autoresearch\targets.json
Copy-Item scripts\autoresearch-check-targets.ps1 scripts\
Copy-Item scripts\autoresearch-overnight.ps1 scripts\
Copy-Item scripts\autoresearch.ps1 scripts\
"commit`tmetric`tstatus`tnotes" | Set-Content data\autoresearch\results.tsv
```

## Telegram test

```powershell
$env:TELEGRAM_CHAT_ID = '-1004292432894'
.\scripts\telegram-notify.ps1 -Message "cursor-config installed" -Level info
```

## Docs

- [VERIFICATION-GATE.md](docs/VERIFICATION-GATE.md)
- [OVERNIGHT.md](docs/OVERNIGHT.md)
- [MCP-SETUP.md](docs/MCP-SETUP.md)
- [DNS.md](docs/DNS.md)
