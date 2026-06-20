#!/usr/bin/env bash
# FROZEN — Grant Verification Gate harness (Unix fallback)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p scripts/verify
LOG="scripts/verify/gate-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

if [[ -f package.json ]]; then
  if jq -e '.scripts.typecheck' package.json >/dev/null 2>&1; then npm run typecheck; fi
  if jq -e '.scripts.build' package.json >/dev/null 2>&1; then npm run build; fi
  if jq -e '.scripts.test' package.json >/dev/null 2>&1; then npm test; fi
fi

echo "RESULT: PASS"
echo "Log: $LOG"
