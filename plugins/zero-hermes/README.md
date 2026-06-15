# zero-hermes (overlay - not directly installable)

This directory is **not** a complete Hermes Agent install on its own. It holds
the Hermes-specific files:

- `manifest.json` - versioned release marker for this adapter
- `hermes/plugin.yaml` - Hermes plugin manifest
- `hermes/__init__.py` - plugin registration for hooks, `/zero`, and the
  plugin-namespaced Zero skill
- `hermes/mcp-zero.yaml` - config fragment for the Zero MCP server

The `zero` skill and `ensure-runner.sh` hook script are copied from
[`../zero/`](../zero/) during packaging. `scripts/build-hermes.sh` rewrites the
skill frontmatter for Hermes while keeping the shared Zero instructions body.

## How the adapter is built

Hermes reads plugins from `~/.hermes/plugins/<name>/` and normal skills from
`~/.hermes/skills/<category>/<name>/`. Plugins are opt-in, so users enable the
Zero plugin with `hermes plugins enable zero` after copying it into place.

`scripts/build-hermes.sh` assembles those pieces into `dist/zero-hermes/`:

```
dist/zero-hermes/
  ├── .hermes/plugins/zero/__init__.py
  ├── .hermes/plugins/zero/hooks/ensure-runner.sh
  ├── .hermes/plugins/zero/plugin.yaml
  ├── .hermes/plugins/zero/skills/zero/SKILL.md
  ├── .hermes/skills/zero/zero/SKILL.md
  ├── hermes/mcp-zero.yaml
  └── manifest.json
```

Hermes has plugin hooks, so this adapter provisions the Zero runner on session
start and injects Zero context through `pre_llm_call`. Hermes does not use hook
output for auto-approve decisions; the `pre_tool_call` hook only blocks
`zero fetch` commands that omit an explicit `--max-pay` cap.
