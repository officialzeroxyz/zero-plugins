# zero-kiro (overlay - not directly installable)

This directory holds Kiro-specific packaging for Zero:

- `POWER.md` - Kiro IDE Power entry point
- `mcp.json` - Kiro Power MCP server configuration for `https://mcp.zero.xyz`
- `steering/` - Power steering instructions
- `agents/zero.json` - optional Kiro CLI custom-agent template with hooks
- `hooks/ensure-runner.sh` - Kiro CLI hook wrapper around the shared runner provisioner
- `hooks/zero-context.sh` - Kiro CLI hook helper that prints plain context
- `manifest.json` - repo version metadata kept in lockstep with the other hosts

The canonical Zero skill lives once in [`../zero/`](../zero/) and is copied into
the build output by `scripts/build-kiro.sh`. User-facing install instructions
are in the [Kiro guide](../../guides/kiro.md).

## How the package is built

```text
plugins/zero-kiro/                 # this overlay
  ├── POWER.md                     # Kiro IDE Power metadata and instructions
  ├── mcp.json                     # Kiro Power MCP config
  ├── agents/zero.json             # optional CLI agent template
  ├── hooks/ensure-runner.sh       # Kiro hook runner provisioning helper
  ├── hooks/zero-context.sh        # Kiro hook context helper
  └── steering/zero.md             # Power steering

scripts/build-kiro.sh              # assembles overlay + shared files -> dist/zero-kiro/

dist/zero-kiro/
  ├── power/                       # folder to import as a Kiro Power
  ├── skills/zero/SKILL.md         # copy to ~/.kiro/skills/zero
  ├── agents/zero.json             # optional copy to ~/.kiro/agents/zero.json
  └── hooks/*.sh                   # optional copy to ~/.kiro/zero/hooks/
```

Kiro Powers do not currently bundle Agent Skills into `.kiro/skills`, so the
standalone guide includes a separate skill-copy step. Kiro CLI hooks are part
of custom agent JSON, not the Power package, so `agents/zero.json` is shipped as
a template for users who want the hook-driven CLI path.
