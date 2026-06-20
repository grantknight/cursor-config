# See skills/autoresearch/references/grant-profile.md for full profile.

Per-stack examples:

| Stack | Editable | Harness |
|-------|----------|---------|
| Node/React | `src/**`, `frontend/src/**` | `npm run build && npm test` |
| FastAPI | `backend/app/**` | `pytest -q` |
| Express | `app/**`, `routes/**` | `npm test && curl localhost/health` |

Frozen in every repo: `scripts/verify-all.ps1`, `scripts/autoresearch-check-targets.ps1`, `scripts/autoresearch-examiner-check.ps1`.

**Autoresearch = overnight.** Entry: `scripts/autoresearch.ps1` (loads secrets, runs loop with examiner built in).
