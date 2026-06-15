# zero-cline (overlay - not directly installable)

This directory is **not** a complete Cline install on its own. It holds the
Cline-specific files that are overlaid with the shared Zero skill from
[`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `cline/zero/mcp.json` - Cline MCP config fragment
- `clinerules/workflows/zero.md` - manual `/zero` workflow

User-facing install instructions are in the
[Cline guide](../../guides/cline.md).

## How the adapter is built

Cline's VS Code and JetBrains extensions do not currently consume Cline SDK
plugins, so this adapter is a project template assembled by
`scripts/build-cline.sh`:

```
plugins/zero-cline/                       # this overlay
  ├── manifest.json                       # versioned adapter metadata
  ├── cline/zero/mcp.json                 # MCP config fragment
  └── clinerules/workflows/zero.md        # /zero workflow

scripts/build-cline.sh                    # assembles overlay + shared files -> dist/zero-cline/

dist/zero-cline/                          # (git-ignored) files to copy into a project:
  ├── manifest.json                       #   <- plugins/zero-cline/
  ├── .cline/
  │   ├── skills/zero/SKILL.md            #   <- plugins/zero/
  │   └── zero/mcp.json                   #   <- plugins/zero-cline/ (merge into Cline MCP config)
  └── .clinerules/
      └── workflows/zero.md               #   <- plugins/zero-cline/
```

## How Cline differs from Claude Code

Cline discovers project skills from `.cline/skills/` (recommended),
`.clinerules/skills/`, and `.claude/skills/`. This template uses
`.cline/skills/zero` only to avoid duplicate `/zero` skill entries.

Cline extension MCP is configured through the Cline UI or the extension's MCP
settings JSON. Cline CLI uses `~/.cline/mcp.json`. The adapter ships
`.cline/zero/mcp.json` as a mergeable config fragment rather than assuming a
project-level MCP file is loaded automatically.

Cline's current plugin and hook docs apply to SDK, CLI, and Kanban, and are not
applicable to the VS Code and JetBrains extensions yet. For that reason this
adapter intentionally does not ship hooks; users install the Zero runner through
the standalone installer.
