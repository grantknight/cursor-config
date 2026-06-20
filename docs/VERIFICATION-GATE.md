# Grant Verification Gate — Council flow

Three layers before you hear "done":

```
Implementer → verify-all.ps1 → code-verifier → visual-verifier → slop-auditor → user
```

## Layer 1 — Frozen harness

Per-project `scripts/verify-all.ps1` (copy from `~/.cursor/templates/scripts/verify-all.ps1`).

- Agent **must not edit** this file during tasks or autoresearch loops
- Exit 0 only when all enabled checks pass
- Logs to `scripts/verify/gate-{timestamp}.log`

Configure via `data/verify/targets.json`.

## Layer 2 — Council subagents

User-level: `~/.cursor/agents/`

| Agent | Output marker |
|-------|----------------|
| code-verifier | `CODE_VERIFY: PASS\|FAIL` |
| visual-verifier | `VISUAL_VERIFY: PASS\|FAIL\|SKIP` |
| slop-auditor | `SLOP_VERIFY: PASS\|FAIL\|SKIP` |

Parent invokes with **readonly** Task/subagent. Implementer never self-certifies.

## Layer 3 — Stop hook

`~/.cursor/hooks/stop-verify.js` runs on agent stop:

- If project has `scripts/verify-all.ps1` and it fails → auto `followup_message` (Ralph loop)
- Max 10 loops (`loop_limit` in hooks.json)
- No verify script in project → hook passes through (no block)

## When to SKIP visual/slop

| Task | Visual | Slop |
|------|--------|------|
| API/backend only | SKIP | SKIP |
| Docs/config | SKIP | SKIP |
| UI/frontend | required | required |
| Deploy + UI | required | required |

## Bootstrap a new project

```powershell
mkdir scripts, scripts\verify, data\verify -Force
Copy-Item "$env:USERPROFILE\.cursor\templates\scripts\verify-all.ps1" scripts\
Copy-Item "$env:USERPROFILE\.cursor\templates\data\verify\targets.json" data\verify\
```

Add `scripts/verify/` to `.gitignore` if screenshots should stay local.

## Overnight (Phase 6)

`autoresearch-check-targets.ps1` calls `verify-all.ps1` — same mechanical gate.

Telegram: SUCCESS only after full council pass; BLOCKED on harness failure or max loops.
