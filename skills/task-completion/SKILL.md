---
name: task-completion
description: >
  Finish work end-to-end without handing steps back to the user. Use when a task
  includes deploy, DB updates, verification, infrastructure, or the user says
  "do it", "until done", "don't ask me to run", or shows ops steps they expect
  you to execute.
---

# Task completion

## Rule

If you can run it (CLI, API, Railway, GitHub, scripts), **you** run it. Do not end with instructions for the user unless you are blocked on secrets, permissions, or irreversible choices.

## Completion checklist

1. **Implement** — code, config, migrations.
2. **Verify locally** — build, tests, smoke scripts; show real output.
3. **Apply to target environment** — production DB, DNS, Railway, etc., when the task implies it.
4. **Deploy** — commit + push or `railway up` when shipping is part of the goal.
5. **Confirm live** — health endpoint, row counts, or UI check; report proof.
6. **Document** — update `AGENTS.md` gotchas/commands if non-obvious.

## Production database (Logbook)

- Use Railway `DATABASE_PUBLIC_URL` from Postgres service; **unset** `PGLITE_DATA_DIR`.
- ICAO + maintenance batch: `npx tsx scripts/run-production-data-fixes.ts` (types) then `fix-production-maintenance.ts` if needed.
- Never paste connection strings or passwords in chat.

## When to stop and ask

- Missing credentials you cannot obtain via linked CLI/MCP.
- Destructive action (delete data, force push) without explicit request.
- Ambiguous product choice that changes behaviour materially.

## Response shape

Lead with **done / not done**, proof (command output or counts), and only mention user action if truly blocked.
