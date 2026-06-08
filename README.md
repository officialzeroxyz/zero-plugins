# zero-plugins

Official Zero plugins — discover and pay for AI capabilities from any agent.

Zero is a search engine and payment layer for AI agents: discover external paid
capabilities (x402 / MPP) — image/video/audio generation, web scraping, data
enrichment, real-time data, messaging — call them, and pay per use with a wallet.
No per-service signup.

## Status

This repo is being built up iteratively, one carefully reviewed PR at a time.
Today it ships the **Codex** plugin only:

```
.agents/plugins/marketplace.json        # Codex marketplace catalog
plugins/zero/
  ├── .codex-plugin/plugin.json          # Codex manifest (declares skills, mcp, hooks)
  ├── .mcp.json                          # Zero MCP connector → https://mcp.zero.xyz
  ├── skills/zero/SKILL.md               # the 'zero' skill (placeholder — filled in iteratively)
  └── hooks/
      ├── hooks.json                     # hook declarations (UserPromptSubmit)
      └── zero-context.sh                # injects a short "Zero is available" reminder per prompt
```

Additional hosts (Claude Code, Cursor, Gemini) and the full skill will land in
subsequent PRs.
