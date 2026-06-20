#!/usr/bin/env node
/**
 * Grant Verification Gate — stop hook (Ralph pattern).
 * Runs scripts/verify-all.ps1 on agent stop; followup_message on failure.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const MAX_LOOPS = 10;

function stripBom(text) {
  return String(text || '').replace(/^\uFEFF/, '');
}

function parseHookInput(raw) {
  const trimmed = stripBom(raw).trim();
  if (!trimmed) return {};
  return JSON.parse(trimmed);
}

function readStdin() {
  return new Promise((resolve) => {
    const chunks = [];
    process.stdin.on('data', (c) => chunks.push(c));
    process.stdin.on('end', () => {
      let buf = Buffer.concat(chunks);
      if (buf.length >= 3 && buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) {
        buf = buf.subarray(3);
      }
      resolve(buf.toString('utf8'));
    });
  });
}

function findVerifyScript(startDir) {
  let dir = startDir;
  for (let i = 0; i < 10; i++) {
    const candidate = path.join(dir, 'scripts', 'verify-all.ps1');
    if (fs.existsSync(candidate)) return { script: candidate, root: dir };
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

function blocked(msg) {
  process.stdout.write(JSON.stringify({ followup_message: msg }));
}

async function main() {
  let input = {};
  try {
    const raw = await readStdin();
    if (stripBom(raw).trim()) input = parseHookInput(raw);
  } catch (e) {
    blocked(
      `Verification gate: stop hook could not parse input (${e.message}). Do not claim done — report BLOCKED and re-run verify-all.ps1.`,
    );
    return;
  }

  const loopCount = input.loop_count ?? input.loopCount ?? 0;
  if (loopCount >= MAX_LOOPS) {
    blocked(
      `Verification gate: max ${MAX_LOOPS} stop-hook loops reached. Report BLOCKED to the user with the last verify-all log. Do not claim success.`,
    );
    return;
  }

  const roots = input.workspace_roots || input.workspaceRoots || [];
  const start = roots[0] || process.cwd();
  const found = findVerifyScript(start);

  if (!found) {
    process.stdout.write('{}');
    return;
  }

  const result = spawnSync(
    'powershell.exe',
    ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', found.script],
    { cwd: found.root, encoding: 'utf8', timeout: 280000, windowsHide: true },
  );

  if (result.status === 0) {
    process.stdout.write('{}');
    return;
  }

  const output = `${result.stdout || ''}\n${result.stderr || ''}`.trim();
  const tail = output.length > 4000 ? output.slice(-4000) : output;

  blocked(
    `scripts/verify-all.ps1 FAILED (exit ${result.status ?? 'unknown'}). Fix all failures. Do NOT tell the user the task is done until verify-all exits 0 and council subagents (code-verifier, visual-verifier, slop-auditor) report PASS.\n\n${tail}`,
  );
}

main().catch((e) => {
  blocked(
    `Verification gate: stop hook error (${e.message}). Report BLOCKED; do not claim success.`,
  );
});
