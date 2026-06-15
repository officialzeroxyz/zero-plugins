# zero-roo (overlay - not directly installable)

This directory is **not** a complete Roo Code project adapter on its own. It
holds the Roo-specific files:

- `manifest.json` - versioned release marker for this adapter
- `roo/mcp.json` - project-level MCP configuration for `https://mcp.zero.xyz`
- `roo/commands/zero.md` - `/zero` command instructions
- `roo/rules/zero.md` - project rule that tells Roo Zero is available
- `roo/marketplace-mcp.json` - exact Zero MCP payload for a future Roo
  Marketplace listing

The `zero` skill is copied from [`../zero/`](../zero/) during packaging so Roo
receives the same skill body as the other hosts.

## How the adapter is built

Roo reads project skills from `.roo/skills/` and `.agents/skills/`, project MCP
servers from `.roo/mcp.json`, project rules from `.roo/rules/`, and project
commands from `.roo/commands/`. `scripts/build-roo.sh` assembles those pieces
into `dist/zero-roo/`:

```
dist/zero-roo/
  ├── .agents/skills/zero/SKILL.md
  ├── .roo/commands/zero.md
  ├── .roo/mcp.json
  ├── .roo/rules/zero.md
  ├── .roo/skills/zero/SKILL.md
  ├── manifest.json
  └── roo/marketplace-mcp.json
```

Roo has no documented lifecycle hooks, so this adapter does not auto-provision
or auto-update the runner. Users install the shared Zero CLI/runtime with the
standalone installer and refresh project files by rebuilding/copying the
adapter.
