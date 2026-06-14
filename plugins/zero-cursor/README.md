# zero-cursor (overlay - not directly installable)

This directory is **not** a complete Cursor install on its own. It holds the
Cursor-specific files that are overlaid with the shared Zero skill and runner
hook from [`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `cursor/mcp.json` - Zero MCP server config
- `cursor/hooks.json` - Cursor session-start runner provisioning
- `cursor/permissions.json` - Auto-review steering for Zero commands
- `cursor/hooks/ensure-runner.sh` - Cursor-shaped wrapper around the shared runner hook

User-facing install instructions are in the
[Cursor guide](../../guides/cursor.md).

## How the adapter is built

Cursor has no one-artifact plugin bundle for local skills, hooks, and MCP
config. `scripts/build-cursor.sh` assembles a project template by combining
this overlay with the shared Zero skill and runner hook:

```
plugins/zero-cursor/                      # this overlay
  ├── manifest.json                       # versioned adapter metadata
  └── cursor/
      ├── hooks.json                      # Cursor sessionStart hook
      ├── hooks/ensure-runner.sh          # Cursor hook-output wrapper
      ├── mcp.json                        # streamable HTTP MCP config
      └── permissions.json                # Auto-review steering only

scripts/build-cursor.sh                   # assembles overlay + shared files -> dist/zero-cursor/

dist/zero-cursor/                         # (git-ignored) files to copy into a project:
  ├── manifest.json                       #   <- plugins/zero-cursor/
  ├── .agents/skills/zero/SKILL.md        #   <- plugins/zero/
  └── .cursor/
      ├── hooks.json                      #   <- plugins/zero-cursor/
      ├── mcp.json                        #   <- plugins/zero-cursor/
      ├── permissions.json                #   <- plugins/zero-cursor/
      ├── skills/zero/SKILL.md            #   <- plugins/zero/
      └── zero/hooks/
          ├── ensure-runner.sh            #   <- plugins/zero-cursor/
          └── ensure-runner-shared.sh     #   <- plugins/zero/
```

## How Cursor differs from Claude Code

Cursor supports Agent Skills and project-level MCP config cleanly, but it does
not have a plugin packaging format. This overlay installs project files instead.

The only active hook is `sessionStart`, which runs a Cursor wrapper around the
shared Zero `ensure-runner.sh` script so `~/.zero/runtime/bin/zero` stays
provisioned and updated. Cursor's permission model is handled by Run Mode and
`.cursor/permissions.json`; this overlay only steers Auto-review with natural
language instructions. It does **not** install a terminal allowlist, because
Cursor treats configured allowlists as replacements for the user's existing
allowlist.
