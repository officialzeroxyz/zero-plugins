# zero-crush (overlay - not directly installable)

This directory is **not** a complete Crush install on its own. It holds the
Crush-specific files:

- `manifest.json` - versioned release marker for this adapter
- `crush/crush.zero.json` - mergeable `crush.json` fragment for Zero MCP and
  the PreToolUse hook
- `crush/hooks/zero-pre-tool-use.sh` - hook script for Zero command gating

The `zero` skill is copied from [`../zero/`](../zero/) during packaging with
Crush frontmatter added (`user-invocable: true`).

## How the adapter is built

Crush reads project skills from `.crush/skills/` and `.agents/skills/`. It does
not have SessionStart or UserPromptSubmit hooks yet, but it can run
`PreToolUse` hooks from `crush.json`.

`scripts/build-crush.sh` assembles those pieces into `dist/zero-crush/`:

```
dist/zero-crush/
  ├── .agents/skills/zero/SKILL.md
  ├── .crush/hooks/zero-pre-tool-use.sh
  ├── .crush/skills/zero/SKILL.md
  ├── crush/crush.zero.json
  └── manifest.json
```

The hook auto-approves read-only Zero runner commands and blocks `zero fetch`
commands that do not include an explicit `--max-pay` cap. Spending commands
with a cap still fall through to Crush's normal permission flow.
