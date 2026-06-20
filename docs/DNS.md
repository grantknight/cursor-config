# DNS — Grant Knight stack

## dragonflight.co.za

| Item | Value |
|------|-------|
| **Authoritative DNS** | Cloudflare |
| **Zone ID** | `04aceaf15c17ca21641d4e8d7be9161b` |
| **Registrar / email** | KonsoleH (not for publishing DNS on this zone) |

**Rule:** DNS edits for this zone go through **Cloudflare MCP** or dashboard — never KonsoleH for publishing.

## Common subdomains

| Host | Points to | App |
|------|-----------|-----|
| `ada.dragonflight.co.za` | Railway ada-helipads | ADA Helipads |
| `www.ada.dragonflight.co.za` | Railway (verify CNAME) | ADA Helipads |

## sop.aero

Separate zone — CNAME to Railway (`zq4ifpyo.up.railway.app` per SOP AGENTS.md). Confirm in Cloudflare before edits.

## KonsoleH

Use for registrar, hosting, email only where NS is still KonsoleH. Check `registry/domains.yaml` in knight-hq-registry (Phase 5C) before assuming.
