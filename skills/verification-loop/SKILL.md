---
name: verification-loop
description: Run build, typecheck, and tests before declaring work done. Use when finishing features, bug fixes, or refactors — or when the user asks to verify, test, or confirm something works.
---

# Verification loop

Mechanical proof before "done". No self-certification without running commands.

## When to use

- Before telling the user a task is complete
- After code changes to UI, API, deploy, or config
- When fixing bugs (prove the fix, not just the patch)

## Standard sequence

Run what the project has (skip missing steps):

1. **Install** — `npm ci` or `npm install` if deps changed
2. **Typecheck** — `npx tsc --noEmit` or project script
3. **Lint** — `npm run lint` if present
4. **Build** — `npm run build` if present
5. **Test** — `npm test` / `pytest` / project test script
6. **Smoke** — curl health endpoint or minimal script if deploy-related
7. **Visual** — Playwright screenshot or cursor-ide-browser if UI changed

## Exit criteria

- All run commands exit 0
- Show actual terminal output (not "should work")
- If a step fails: fix and re-run from step 2

## Project detection

Read `package.json` scripts first. Prefer existing project scripts over inventing new ones.

## Pair with

- `task-completion` — finish deploy/infra without handing back steps
- `95-visual-verification.mdc` rule — screenshot for UI work
- Phase 4 `verify-all.ps1` — frozen per-project harness (when installed)
