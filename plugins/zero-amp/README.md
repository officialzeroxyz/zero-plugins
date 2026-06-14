# zero-amp (overlay - not directly installable)

This directory holds Amp-specific packaging for Zero:

- `manifest.json` - version metadata kept in lockstep with other hosts
- `skill/mcp.json` - embedded MCP config copied into the Zero skill directory
- `plugins/zero.ts` - Amp TypeScript plugin for runner provisioning, prompt
  context, a command-palette entry, and safe Zero command allow rules
- `hooks/zero-context.sh` - helper used by the Amp command-palette entry

The canonical Zero skill and shared runner provisioner live once in
[`../zero/`](../zero/) and are copied into the build output by
`scripts/build-amp.sh`. User-facing install instructions are in the
[Amp guide](../../guides/amp.md).

## How the package is built

```text
plugins/zero-amp/                  # this overlay
  ├── manifest.json                # version metadata
  ├── skill/mcp.json               # embedded MCP config
  ├── plugins/zero.ts              # Amp plugin
  └── hooks/zero-context.sh        # command helper

scripts/build-amp.sh               # assembles overlay + shared files -> dist/zero-amp/

dist/zero-amp/
  ├── .agents/skills/zero/         # project skill with embedded mcp.json
  ├── .amp/plugins/zero.ts         # project plugin
  └── .amp/zero/hooks/             # hook/helper scripts used by the plugin
```

Amp reads project plugins from `.amp/plugins/*.ts` and project skills from
`.agents/skills/`. The embedded `mcp.json` keeps Zero MCP tools scoped to the
Zero skill instead of adding them to every Amp turn.
