# Grant Verification Gate — Council flow

Three layers before you hear "done":

```
Implementer → verify-all.ps1 → metrics PASS → examiner council → code-verifier → visual-verifier → slop-auditor → user
```

## Layer 2.5 — Examiner Mode (overnight only)

When `examinerRequired: true` in `data/autoresearch/targets.json`:

1. `autoresearch-examiner-gate.ps1` runs after harness + metrics PASS
2. Three tier examiners (top / mid / low) plan questions, grade evidence
3. `autoresearch-examiner-check.ps1` prints `EXAMINER_VERIFY: PASS|FAIL`
4. Telegram SUCCESS only after `EXAMINER_VERIFY: PASS`

See [EXAMINER-MODE.md](EXAMINER-MODE.md).

## Layer 1 — Frozen harness (2026-06-20 hardening)

- **npm exit codes:** native commands run via `cmd /c` so failures are not masked by PowerShell pipes
- **Required flags fail closed:** if `buildPasses`/`testsPass`/`typecheck`/`visualRequired`/`slopCheckRequired` is true but the step cannot run, harness exits **1** (not SKIP)
- **Slop:** when `slopCheckRequired: true`, runs `node ~/.cursor/skills/impeccable/scripts/detect.mjs`
- **Default targets.json:** all flags **false** for harness-only / config repos (enable per project)

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
