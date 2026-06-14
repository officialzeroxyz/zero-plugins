# zero (the shared plugin)

The one source of truth for the Zero plugin's content, shared by every host:

- `skills/zero/SKILL.md` — the host-agnostic `zero` skill
- `hooks/` — `ensure-runner.sh` (SessionStart), `zero-context.sh`
  (UserPromptSubmit), `auto-approve-zero.sh` (PreToolUse), declared in
  `hooks.json`
- `.claude-plugin/plugin.json` — Claude Code manifest
- `.codex-plugin/plugin.json` — Codex manifest
- `.factory-plugin/plugin.json` — Droid manifest
- `.github/plugin/plugin.json` — GitHub Copilot manifest
- `.mcp.json` — the Zero MCP connector for Claude hosts
- `mcp-copilot.json` — the Zero MCP connector for Copilot hosts

The skill and hook scripts are byte-identical across Claude Code, Codex, and
Gemini (the Gemini extension is assembled from this directory plus the
[`../zero-gemini/`](../zero-gemini/) overlay) — they live only here and are
never copied into the repo, so they can't drift.

User-facing install instructions live in [`guides/`](../../guides/).

## Notes

- **`.mcp.json` must stay `mcpServers`-wrapped.** It uses the documented
  `{"mcpServers": {...}}` shape because claude.ai's plugin loader is stricter
  than the CLI and silently drops the connector otherwise.
- **The Codex manifest deliberately declares no MCP server.** The connector's
  one hard job is authenticating in ephemeral sandboxes, and the Codex
  surfaces that load plugins (app, CLI) are persistent, while Codex cloud
  loads neither plugins nor MCP.
- **Hook output is Claude-shaped JSON** (`hookSpecificOutput.additionalContext`
  plus a `hookEventName` sibling). Codex reads it natively and Gemini's parser
  ignores the extra field, which is what lets the scripts run unchanged on all
  three hosts.
