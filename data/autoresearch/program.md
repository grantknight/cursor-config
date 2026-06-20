# Cursor setup audit — autoresearch program

## Goal

Improve Grant Knight user-level Cursor setup so autonomous work succeeds more and fails less.

## Editable surface (agents MAY change)

- `~/.cursor/` via `cursor-config/scripts/install.ps1` source files in `cursor-config/`
- `cursor-config/scripts/verify-all.ps1` (frozen template — change only with council agreement)
- `cursor-config/scripts/autoresearch*.ps1`
- `cursor-config/docs/*.md`
- `cursor-template/data/verify/targets.json` (test harness project)

## Invariants (NEVER break)

- Agents must NOT edit per-project `scripts/verify-all.ps1` during loops
- No secrets in git
- No new MCP servers without council definite-benefit approval
- No skill bloat — max 10 user skills

## Harness

```powershell
cd cursor-config
powershell -File scripts/verify-all.ps1   # from a bootstrapped test project
powershell -File scripts/autoresearch-check-targets.ps1  # in cursor-template
```

## Metric

`audit_findings_resolved` — count of council-agreed fixes implemented and verified per pass.

## Council lenses each pass

1. Verification gate (false PASS paths)
2. User-level install coverage
3. Overnight loop reliability
4. UI slop prevention wiring

Stop when two consecutive passes produce zero definite-benefit findings.
