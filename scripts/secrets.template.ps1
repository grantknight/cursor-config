# Copy values into Windows User environment variables (Settings > System > Environment).
# Never commit real values. Restart Cursor after changes.
#
# Required for MCP (Phase 0):
#   GITHUB_TOKEN          GitHub PAT for MCP (repo scope as needed)
#   RAILWAY_API_TOKEN     Railway API token
#   Z_AI_API_KEY          Removed from MCP in Phase 2 (optional env var only)
#   OPENROUTER_API_KEY    Only if using OpenRouter via openai.baseUrl in settings
#
#   CLOUDFLARE_API_TOKEN    Cloudflare API token (bearer auth — skip OAuth in Cursor)
#   CLOUDFLARE_ACCOUNT_ID   Optional; your Cloudflare account id
#
# Overnight alerts (Telegram — Knight HQ bot):
#   TELEGRAM_BOT_TOKEN    Same bot as PaperClip/Hermes if you prefer
#   TELEGRAM_CHAT_ID      e.g. -1004292432894 (Knight HQ group)
#   TELEGRAM_TOPIC_ID     Optional forum topic for Cursor alerts
