# Grant autoresearch profile

Default profile for Grant Knight projects. Per-repo overrides live in `data/autoresearch/program.md`.

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

## Infrastructure defaults

- **Deploy:** Railway MCP or `railway up` — agent runs it
- **DNS:** Cloudflare only for `dragonflight.co.za` (never KonsoleH for that zone)
- **GitHub:** branch + PR when shipping; never force-push main

## Autonomy

- No AskQuestion in overnight mode — use repo `AGENTS.md` + `targets.json`
- Block only on: missing secrets, destructive ops, broken harness

## Headless driver

- `scripts/autoresearch-overnight.ps1` + `cursor-agent` CLI
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
- Harness / benchmark files listed in `program.md`

## Interactive vs overnight

| Mode | Behavior |
|------|----------|
| Interactive | One confirmation after goal parse (Muminur default) |
| Overnight | Skip questions; read this profile + repo AGENTS.md |
