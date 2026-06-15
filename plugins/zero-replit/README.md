# zero-replit (overlay - not directly installable)

This directory is **not** a complete Replit install on its own. It holds the
Replit-specific files that are overlaid with the shared Zero skill from
[`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `replit/mcp-install.json` - Replit MCP install-link payload

User-facing install instructions are in the
[Replit guide](../../guides/replit.md).

## How the adapter is built

Replit Agent does not have a third-party plugin bundle, local hooks, or a
project-level MCP config file. The adapter is a project template assembled by
`scripts/build-replit.sh`:

```
plugins/zero-replit/                      # this overlay
  ├── manifest.json                       # versioned adapter metadata
  └── replit/mcp-install.json             # Add-to-Replit payload

scripts/build-replit.sh                   # assembles overlay + shared files -> dist/zero-replit/

dist/zero-replit/                         # (git-ignored) files to copy into a Replit project:
  ├── manifest.json                       #   <- plugins/zero-replit/
  ├── .agents/skills/zero/SKILL.md        #   <- plugins/zero/
  └── replit/mcp-install.json             #   <- plugins/zero-replit/
```

## How Replit differs from Claude Code

Replit Agent discovers project skills from `/.agents/skills`. Installed skills
persist with the project and can be committed to version control.

Replit MCP is configured through the Integrations pane or an install link. It
does not use a JSON config file in the project. The payload in
`replit/mcp-install.json` exists so docs, PRs, and future marketplace/listing
work can point at the exact Zero MCP server details.

Replit Agent has no lifecycle hooks, tool-approval hooks, or prompt-submit hooks
for project files, so this adapter intentionally ships no hooks. Users install
the Zero runner through the standalone installer when shell access is available,
and use the Replit MCP integration for hosted Agent access.
