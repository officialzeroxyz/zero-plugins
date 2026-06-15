# zero-devin (overlay - not directly installable)

This directory is **not** a complete Devin Desktop / Windsurf install on its
own. It holds the Devin-specific files that are overlaid with the
shared Zero skill from [`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `devin/config.json` - Devin Local / CLI MCP config
- `devin/hooks.v1.json` - Devin Local / CLI hooks
- `devin/hooks/auto-approve-zero.sh` - Devin permission hook for read-only Zero commands
- `devin/rules/zero.md` - always-on Zero routing rule for Devin Desktop
- `windsurf/mcp_config.json` - Cascade MCP server config fragment
- `windsurf/workflows/zero.md` - manual Cascade `/zero` workflow

User-facing install instructions are in the
[Devin Desktop guide](../../guides/devin-desktop.md).

## How the adapter is built

Devin Desktop has no plugin bundle format for local skills, workflows, MCP
config, and hooks. The adapter is a project template assembled by
`scripts/build-devin.sh`:

```
plugins/zero-devin/                       # this overlay
  ├── manifest.json                       # versioned adapter metadata
  ├── devin/
  │   ├── config.json                     # Devin Local / CLI MCP config
  │   ├── hooks.v1.json                   # Devin Local / CLI hooks
  │   ├── hooks/auto-approve-zero.sh      # permission decision hook
  │   └── rules/zero.md                   # Desktop + CLI routing rule
  └── windsurf/
      ├── mcp_config.json                 # streamable HTTP MCP config fragment
      └── workflows/zero.md               # Cascade /zero workflow

scripts/build-devin.sh                    # assembles overlay + shared files -> dist/zero-devin/

dist/zero-devin/                          # (git-ignored) files to copy into a project:
  ├── manifest.json                       #   <- plugins/zero-devin/
  ├── .agents/skills/zero/SKILL.md        #   <- plugins/zero/
  ├── .devin/
  │   ├── config.json                     #   <- plugins/zero-devin/
  │   ├── hooks.v1.json                   #   <- plugins/zero-devin/
  │   ├── rules/zero.md                   #   <- plugins/zero-devin/
  │   ├── skills/zero/SKILL.md            #   <- plugins/zero/
  │   └── zero/hooks/                     #   <- plugins/zero + overlay hook wrappers
  └── .windsurf/
      ├── mcp_config.json                 #   <- plugins/zero-devin/ (paste/merge into user config)
      └── workflows/zero.md               #   <- plugins/zero-devin/
```

## How Devin Desktop differs from Claude Code

Devin Desktop currently has two agent surfaces:

- Cascade discovers workspace skills from `.windsurf/skills/`, portable skills
  from `.agents/skills/`, and rules from `.devin/rules/` first with
  `.windsurf/rules/` as a legacy fallback. This template uses `.agents/skills/`
  for the shared Zero skill to avoid duplicate `/zero` entries when Devin Local
  imports Windsurf files. Workflows in `.windsurf/workflows/` are manual slash
  commands, so this adapter ships a `/zero` workflow for explicit invocation.
- Devin Local / CLI uses `.devin/config.json`, `.devin/skills/`, and
  `.devin/hooks.v1.json`.

Cascade hooks are block/logging hooks and do not provide the same runner
provisioning surface as Devin Local / CLI. The template therefore uses Devin
Local / CLI hooks for runner provisioning and permission decisions, while
Cascade users can install the runner with the standalone installer.
