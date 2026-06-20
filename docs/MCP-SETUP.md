# MCP stack (Phase 2)

Active servers in `~/.cursor/mcp.json`:

| Server | Type | Notes |
|--------|------|--------|
| github | Remote | Needs `GITHUB_TOKEN` user env var |
| railway | stdio | Needs `RAILWAY_API_TOKEN` + **Node.js on PATH** for Cursor child process |
| playwright | stdio | Needs **Node.js/npx on PATH** |
| cloudflare | Remote | OAuth on first use in Cursor → Settings → MCP |

## Fix red MCP servers (checklist)

| Server | If red, do this |
|--------|-----------------|
| **github** | User env var `GITHUB_TOKEN` must exist **before** Cursor starts. Set in Windows Settings → System → Environment → User variables. **Fully quit Cursor** (not just reload window). PAT needs repo scopes. |
| **railway** | Account token at https://railway.app/account/tokens → set `RAILWAY_API_TOKEN` in User env vars → run `~/.cursor/sync-mcp-secrets.ps1` → restart Cursor. Uses `mcp.secrets.env` (Windows `${env:...}` often fails in MCP child process). |
| **playwright** | Uses `C:\Program Files\nodejs\npx.cmd` (Windows). Restart Cursor after Node install. |
| **cloudflare** | **Skip OAuth** (browser hang + "Missing code" on refresh is normal; OAuth can succeed but Cursor then hits SSE 404). Create API token → set `CLOUDFLARE_API_TOKEN` in User env vars → restart Cursor. Run **Cursor: Clear All MCP Tokens** once to drop stale OAuth state. |

If `${env:...}` still fails for github: set token in Cursor MCP UI (pencil icon on github server) as temporary fix, then move back to env var after confirming green.

## Cloudflare API token (recommended — skip OAuth)

OAuth in Cursor often: browser hangs after Authorize → refresh shows **Invalid Request / Missing code** → MCP still red.

That is expected: Cursor steals the one-time auth code via `cursor://` redirect; refreshing the browser tab always fails. Logs show OAuth can succeed, then **SSE stream 404** breaks the connection anyway.

**Use a bearer token instead** (Cloudflare-supported for CI/automation):

1. https://dash.cloudflare.com/profile/api-tokens → **Create Token**
2. Template: **Edit zone DNS** (or custom: Zone DNS Edit + Zone Read for your zones)
3. Windows User env var: `CLOUDFLARE_API_TOKEN` = token value
4. Cursor: `Ctrl+Shift+P` → **Cursor: Clear All MCP Tokens**
5. Fully quit and restart Cursor
6. Do **not** click Connect/OAuth on cloudflare in MCP panel

Optional: `CLOUDFLARE_ACCOUNT_ID` in User env vars (helps agents; not required in mcp.json).

**Health check:** `scripts/test-cloudflare-mcp.ps1` — lists zones (pass). Zone-scoped DNS tokens often return **401** on `/user/tokens/verify`; that is normal and does not mean MCP is broken.

## Node.js required

Railway and Playwright MCP run via `npx`/`railway` CLI. If MCP shows red for those servers, install Node LTS and ensure `node` and `npx` are on your **user PATH** (new terminal: `node -v`).

```powershell
winget install OpenJS.NodeJS.LTS
```

Then restart Cursor.

## Removed (Phase 2)

manus, codegraph, graphify, zai-*, cloudflare-bindings-only
