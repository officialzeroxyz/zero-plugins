# zero-kilo (overlay - not directly installable)

This directory is **not** a complete Kilo Code project adapter on its own. It
holds the Kilo-specific files:

- `manifest.json` - versioned release marker for this adapter
- `kilo/kilo.jsonc` - project-level Kilo config for Zero MCP and permissions
- `kilo/legacy-mcp.json` - legacy `.kilocode/mcp.json` compatibility payload
- `kilo/commands/zero.md` - `/zero` workflow command instructions
- `kilo/rules/zero.md` - project rule that tells Kilo Zero is available
- `kilo/marketplace-mcp.json` - exact Zero MCP payload for a future Kilo
  Marketplace listing
- `kilo/remote-skills/index.json` - hostable `skills.urls` index

The `zero` skill is copied from [`../zero/`](../zero/) during packaging so Kilo
receives the same skill body as the other hosts.

## How the adapter is built

Kilo reads project skills from `.kilo/skills/`, compatibility skills from
`.agents/skills/` and `.claude/skills/`, project config from `kilo.jsonc` or
`.kilo/kilo.jsonc`, custom rules listed in the config `instructions` array, and
workflow commands from `.kilo/commands/`.
`scripts/build-kilo.sh` assembles those pieces into `dist/zero-kilo/`:

```
dist/zero-kilo/
  ├── .agents/skills/zero/SKILL.md
  ├── .claude/skills/zero/SKILL.md
  ├── .kilo/commands/zero.md
  ├── .kilo/kilo.jsonc
  ├── .kilo/rules/zero.md
  ├── .kilo/skills/zero/SKILL.md
  ├── .kilocode/mcp.json
  ├── kilo/marketplace-mcp.json
  ├── kilo/remote-skills/index.json
  ├── kilo/remote-skills/zero/SKILL.md
  └── manifest.json
```

Kilo has no documented lifecycle hooks, so this adapter does not auto-provision
or auto-update the runner. Users install the shared Zero CLI/runtime with the
standalone installer and refresh project files by rebuilding/copying the
adapter.
