# zero-warp (overlay - not directly installable)

This directory is **not** a complete Warp install on its own. It holds the
Warp-specific files that are overlaid with the shared Zero skill from
[`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `warp/.mcp.json` - Zero MCP server config

User-facing install instructions are in the [Warp guide](../../guides/warp.md).

## How the adapter is built

Warp has no plugin bundle or lifecycle hook format for this adapter. The
adapter is a project template assembled by `scripts/build-warp.sh`:

```
plugins/zero-warp/                        # this overlay
  ├── manifest.json                       # versioned adapter metadata
  └── warp/.mcp.json                      # streamable HTTP MCP config

scripts/build-warp.sh                     # assembles overlay + shared files -> dist/zero-warp/

dist/zero-warp/                           # (git-ignored) files to copy into a project:
  ├── manifest.json                       #   <- plugins/zero-warp/
  ├── .agents/skills/zero/SKILL.md        #   <- plugins/zero/
  └── .warp/
      ├── .mcp.json                       #   <- plugins/zero-warp/
      └── skills/zero/SKILL.md            #   <- plugins/zero/
```

## How Warp differs from Claude Code

Warp discovers Agent Skills directly and exposes skills as slash commands, so
the shared Zero skill is the user-facing `/zero` surface. Warp also supports
MCP via `.warp/.mcp.json`.

Warp does not provide lifecycle hooks equivalent to `SessionStart`,
`UserPromptSubmit`, or `PreToolUse`. The Zero runner must be installed by the
standalone installer, and command approval is handled by Warp Agent Profiles
and Permissions rather than by adapter code.
