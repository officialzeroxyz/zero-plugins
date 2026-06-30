# zero-zed (overlay - not directly installable)

This directory is **not** a complete Zed project adapter on its own. It holds
the Zed-specific files:

- `manifest.json` - versioned release marker for this adapter
- `zed/settings.json` - project settings fragment for the Zero MCP server and
  conservative Zero tool permissions

The `zero` skill is copied from [`../zero/`](../zero/) during packaging so Zed
receives the same skill body as the other hosts.

## How the adapter is built

Zed loads project-local skills from `.agents/skills/`, project settings from
`.zed/settings.json`, and remote MCP servers from the `context_servers` setting.
`scripts/build-zed.sh` assembles those pieces into `dist/zero-zed/`:

```
dist/zero-zed/
  ├── .agents/skills/zero/SKILL.md
  ├── .zed/settings.json
  └── manifest.json
```

Zed has no documented lifecycle hooks. The packaged settings intentionally
auto-allow only low-risk read-only Zero terminal commands and the `zero` skill;
`zero fetch`, `zero review`, and wallet/auth-changing commands still require
confirmation.

Zed's MCP extension API starts command-backed context servers from Rust/Wasm
extension code. Zero's MCP server is already a remote HTTP server with OAuth, so
this adapter uses Zed's native `context_servers.zero.url` setting instead of a
local proxy extension.
