# zero-continue (overlay - not directly installable)

This directory is **not** a complete Continue install on its own. It holds the
Continue-specific files that are overlaid with the shared Zero skill and hooks
from [`../zero/`](../zero/):

- `manifest.json` - versioned metadata for this adapter
- `continue/settings.json` - Continue CLI hook wiring
- `continue/mcpServers/zero.yaml` - Zero MCP server config
- `continue/prompts/zero.md` - `/zero` prompt for Continue

User-facing install instructions are in the
[Continue CLI guide](../../guides/continue-cli.md).

## How the adapter is built

Continue does not have a one-artifact plugin installer for skills and hooks.
`scripts/build-continue.sh` assembles an installable project template by
combining this overlay with the shared skill and hook scripts:

```
plugins/zero-continue/                    # this overlay
  ├── manifest.json                       # versioned adapter metadata
  └── continue/
      ├── settings.json                   # Continue CLI hooks
      ├── mcpServers/zero.yaml            # streamable HTTP MCP config
      └── prompts/zero.md                 # invokable /zero prompt

scripts/build-continue.sh                 # assembles overlay + shared files -> dist/zero-continue/

dist/zero-continue/                       # (git-ignored) files to copy into a project:
  ├── manifest.json                       #   <- plugins/zero-continue/
  ├── .claude/skills/zero/SKILL.md        #   <- plugins/zero/ (Continue compat path)
  └── .continue/
      ├── settings.json                   #   <- plugins/zero-continue/
      ├── skills/zero/SKILL.md            #   <- plugins/zero/
      ├── mcpServers/zero.yaml            #   <- plugins/zero-continue/
      ├── prompts/zero.md                 #   <- plugins/zero-continue/
      └── zero/hooks/
          ├── auto-approve-zero.sh        #   <- plugins/zero/
          ├── ensure-runner.sh            #   <- plugins/zero/
          └── zero-context.sh             #   <- plugins/zero/
```

## How Continue differs from Claude Code

Continue CLI's hook system is intentionally Claude Code-compatible, but it
loads project hooks from `.continue/settings.json` as well as `.claude/`.
This overlay uses the Continue-owned path so it does not require users to
install the Claude Code plugin too.

The shared hook scripts run unchanged:

- `SessionStart` provisions the Zero runner.
- `UserPromptSubmit` injects the Zero availability reminder.
- `PreToolUse` auto-approves read-only `zero search`, `zero get`,
  `zero review`, and `zero runs` shell calls.

Continue executes hooks from the project root and sets `CONTINUE_PROJECT_DIR`,
so `settings.json` invokes scripts through that environment variable.
