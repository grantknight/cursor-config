# Design system starter (new projects)

Copy to `/docs/DESIGN_SYSTEM.md` in each project and customize.

## Identity

- **Mode:** dark (default for Grant stack)
- **Inspiration:** Linear / Vercel — tight hierarchy, intentional type, no template hero

## Color (OKLCH preferred)

| Token | Role |
|-------|------|
| `--bg` | Page background |
| `--surface` | Cards, panels |
| `--ink` | Primary text |
| `--muted` | Secondary text |
| `--accent` | Primary action (not default `#3b82f6`) |
| `--accent-2` | Secondary brand accent |

## Type

- **Display:** Rajdhani or project-specific (never system-only)
- **Body:** 14px / 20px line-height
- **Scale:** 4px grid spacing

## Components

- Buttons: filled accent + ghost variant; hover + focus visible
- Cards: subtle border, not flat grey boxes
- Forms: labels, error states, 44px min touch targets on mobile

## Anti-slop (Impeccable)

Run `node ~/.cursor/skills/impeccable/scripts/detect.mjs` before shipping UI.

Fail: purple gradients, Inter-only, uniform card grid, default blue CTAs.
