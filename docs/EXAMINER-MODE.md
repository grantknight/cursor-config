# Examiner Mode (built into autoresearch)

Layer 2.5 — adversarial breadth check before Telegram SUCCESS. **Part of every autoresearch run** (`autoresearch.ps1` = overnight loop). No separate activation.

## Why

Agents pass mechanical verification while doing shallow work: only the top-star GitHub repo, only the obvious perf fix, no edge cases. Examiner Mode acts like a council of examiners who test whether work was done across **three tiers**.

## Council

| Agent | Tier | Tests |
|-------|------|-------|
| `examiner-top` | Top | Mainstream / obvious (highest stars, default path) |
| `examiner-mid` | Mid | Credible alternative agents skip |
| `examiner-low` | Low | Edge case, failure mode, obscure option |

**Unanimous rule:** all three tiers must PASS. Any FAIL sends the loop back.

## Flow

```
verify-all + metrics PASS
  -> autoresearch-examiner-gate.ps1
       Plan: 3 tier questions -> examiner-questions.json
       Answer: implementer fills examiner-answers.json with evidence
       Grade: 3 readonly examiners -> examiner-report.json
       Check: autoresearch-examiner-check.ps1 -> EXAMINER_VERIFY: PASS|FAIL
  -> FAIL: retry (max examinerMaxRetries) then BLOCKED
  -> PASS: Telegram SUCCESS
```

## Per-repo files

```
data/autoresearch/
  examiner-questions.json
  examiner-answers.json
  examiner-report.json
```

Templates: `~/.cursor/templates/autoresearch/examiner-*.template.json`

## Config (`targets.json`)

Examiner is **on by default**. Optional knobs:

```json
{
  "examinerRequired": true,
  "examinerMaxRetries": 3
}
```

Set `"examinerRequired": false` only for harness-only smoke tests (not normal autoresearch).

## program.md section

```markdown
## Examiner mode
Goal: one sentence
Examiner dimensions: what top/mid/low mean for this repo
```

## Examples

**UI research goal**
- Top: Did you evaluate the #1 starred component library?
- Mid: Did you compare a credible alternative (different design system)?
- Low: Did you check an unmaintained or edge-case repo / accessibility failure?

**Performance goal**
- Top: Did you optimize the hot path?
- Mid: Did you try a different algorithm or data structure?
- Low: Did you test worst-case input or cold-start latency?

## Dry-run test (no cursor-agent)

```powershell
.\scripts\autoresearch-examiner-gate.ps1 -RepoRoot . -DryRun
.\scripts\autoresearch-examiner-check.ps1 -RepoRoot .
```

## Markers

- `EXAMINER_TIER: PASS|FAIL` — each examiner agent first line
- `EXAMINER_VERIFY: PASS|FAIL` — frozen checker output

## Frozen scripts (do not edit during loops)

- `scripts/autoresearch-examiner-check.ps1`
- `scripts/autoresearch-examiner-gate.ps1` (orchestrator — config only via targets.json)
