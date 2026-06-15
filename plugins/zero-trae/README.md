# zero-trae (overlay - not directly installable)

This directory is **not** a complete Trae project adapter on its own. It holds
the Trae-specific files:

- `manifest.json` - versioned release marker for this adapter
- `trae/mcp.json` - project-level MCP configuration for `https://mcp.zero.xyz`
- `trae/mcp-install-link.txt` - equivalent Trae MCP import link
- `trae/rules/zero.md` - always-on project rule that tells Trae Zero is available
- `trae/commands/zero.md` - `/zero` command instructions

The `zero` skill is copied from [`../zero/`](../zero/) during packaging so
Trae receives the same skill body as the other hosts.

## How the adapter is built

Trae reads project skills from `.trae/skills/`, optionally reads the Agent
Skills convention from `.agents/skills/`, loads project MCP servers from
`.trae/mcp.json` when the project MCP toggle is enabled, reads project rules
from `.trae/rules/`, and reads custom commands from `.trae/commands/`.

`scripts/build-trae.sh` assembles those pieces into `dist/zero-trae/`:

```
dist/zero-trae/
  ├── .agents/skills/zero/SKILL.md
  ├── .trae/commands/zero.md
  ├── .trae/mcp.json
  ├── .trae/rules/zero.md
  ├── .trae/skills/zero/SKILL.md
  ├── manifest.json
  └── trae/mcp-install-link.txt
```

Trae has no documented lifecycle hooks, so this adapter does not auto-provision
or auto-update the runner. Users install the shared Zero CLI/runtime with the
standalone installer and refresh project files by rebuilding/copying the
adapter.
