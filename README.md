# zero-plugins

Official Zero plugins — discover and pay for AI capabilities from any agent.

Zero is a search engine and payment layer for AI agents: discover external paid
capabilities (x402 / MPP) — image/video/audio generation, web scraping, data
enrichment, real-time data, messaging — call them, and pay per use with a wallet.
No per-service signup.

## Status

This repo is being built up iteratively, one carefully reviewed PR at a time.
Today it ships the **Codex** and **Claude Code** plugins, both backed by the same
`plugins/zero/` directory:

```
.agents/plugins/marketplace.json        # Codex marketplace catalog
.claude-plugin/marketplace.json         # Claude Code marketplace catalog
plugins/zero/
  ├── .codex-plugin/plugin.json          # Codex manifest (declares skills, mcp, hooks)
  ├── .claude-plugin/plugin.json         # Claude Code manifest (inline mcp; skills/hooks auto-discovered)
  ├── .mcp.json                          # Zero MCP connector (Codex; flattened) → https://mcp.zero.xyz
  ├── skills/zero/SKILL.md               # the 'zero' skill — runner, auth, the search→call→review loop
  └── hooks/
      ├── hooks.json                     # hook declarations
      ├── ensure-runner.sh               # SessionStart: provisions the @zeroxyz/cli runner
      ├── zero-context.sh                # UserPromptSubmit: injects a short "Zero is available" reminder
      └── auto-approve-zero.sh           # PreToolUse: auto-approves the runner's own commands
```

Both hosts share one login via `~/.zero`. The Claude manifest declares its MCP
server inline (Claude Code auto-discovers `skills/` and `hooks/hooks.json`), so
the Codex-flattened `.mcp.json` is left untouched.

Install in Claude Code:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Install in Codex:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Additional hosts (Cursor, Gemini) will land in subsequent PRs.
