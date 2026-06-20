# Grant autoresearch profile

Default profile for Grant Knight projects. Per-repo overrides live in `data/autoresearch/program.md`.

## Autoresearch = overnight (one thing)

**Autoresearch and overnight are the same loop.** Single entry point:

```powershell
.\scripts\autoresearch.ps1
```

That script loads secrets and runs `autoresearch-overnight.ps1`. There is no separate "overnight mode" or "examiner mode" to turn on — examiner council is **always** part of autoresearch unless `examinerRequired: false` in `targets.json` (advanced opt-out only).

## Loop (Karpathy ratchet)

1. Read `results.tsv` + `targets.json`
2. ONE change in editable surface only
3. Run harness (frozen — agent cannot edit harness files)
4. Metric improved → git commit KEEP; else git reset DISCARD
5. Repeat until all targets pass OR 07:00 local OR max experiments

## Harness stack (run before KEEP)

- build / typecheck / tests (detect from `package.json`)
- Playwright screenshot → `scripts/verify/{experiment}.png`
- Live URL health check if deploy task (Railway endpoint)
- Telegram notify on SUCCESS / BLOCKED via `telegram-notify.ps1` (Phase 6)

## Examiner (built into autoresearch — step before SUCCESS)

After harness + metrics PASS, autoresearch always runs:

1. `autoresearch-examiner-gate.ps1` — plan / answer / grade phases
2. `autoresearch-examiner-check.ps1` — frozen mechanical check
3. All three tiers (top, mid, low) must PASS; max retries in `examinerMaxRetries`

No separate activation. See `docs/EXAMINER-MODE.md`. Frozen examiner scripts must not be edited during loops.

## Infrastructure defaults

- **Deploy:** Railway MCP or `railway up` — agent runs it
- **DNS:** Cloudflare only for `dragonflight.co.za` (never KonsoleH for that zone)
- **GitHub:** branch + PR when shipping; never force-push main

## Autonomy

- No AskQuestion in overnight mode — use repo `AGENTS.md` + `targets.json`
- Block only on: missing secrets, destructive ops, broken harness

## Headless driver

- `scripts/autoresearch.ps1` → `autoresearch-overnight.ps1` + `cursor-agent` CLI (includes examiner)
- Secrets: Windows User env vars + optional `~/.cursor-config-secrets.ps1` for Telegram

## Repo deliverables (generate on first setup)

```
data/autoresearch/
  targets.json
  program.md      # include Grant profile + repo-specific editable/frozen surface
  results.tsv
scripts/
  autoresearch-check-targets.ps1
  autoresearch-overnight.ps1
  autoresearch.ps1
```

## Frozen surface (never edit during loop)

- `scripts/verify-all.ps1` (Phase 4)
- `scripts/autoresearch-check-targets.ps1`
- `scripts/autoresearch-examiner-check.ps1`
- Harness / benchmark files listed in `program.md`

## Interactive chat vs autoresearch script

| When you say… | What runs |
|---------------|-----------|
| "autoresearch", "run overnight", "keep improving overnight" | `.\scripts\autoresearch.ps1` — full loop + examiner + Telegram |
| Interactive `/autoresearch` in chat (no script) | Agent follows skill loop in-session; for Grant repos with `data/autoresearch/`, prefer launching `autoresearch.ps1` instead |

Autoresearch script mode skips AskQuestion; reads this profile + repo `AGENTS.md`.
