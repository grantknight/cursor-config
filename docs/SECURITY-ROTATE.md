# Token rotation (required after Phase 0)

These tokens were previously stored in plain text in `mcp.json` and `settings.json`.
They are now in **Windows User environment variables** only. **Rotate each one** because they may have been exposed in logs or chat.

| Token | Where to rotate |
|-------|-----------------|
| GitHub PAT | https://github.com/settings/tokens |
| Railway API | Railway dashboard → Account → Tokens |
| Z.ai API | Z.ai console (optional; zai MCP removed in Phase 2) |
| OpenRouter | https://openrouter.ai/keys |

After rotating, update User env vars and **fully quit + restart Cursor**.

Backup of old config: `Desktop/cursor-cleanup-backup/mcp.json.bak`
