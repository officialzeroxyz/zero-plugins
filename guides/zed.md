# Zero for Zed

How to install Zero in Zed and keep it up to date.

## Install

### Inside Zed

For the full Claude Code plugin experience inside Zed, install Claude Agent
from Zed's ACP Registry, then install Zero using the
[Claude Code guide](claude-code.md). That path runs Claude Code in Zed's Agent
Panel, so Zero's existing Claude Code plugin, hooks, and `/zero` command work
unchanged.

For Zed's native Agent, install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Zed adapter from this repository, then copy it into your project:

```bash
scripts/build-zed.sh
cp -R dist/zero-zed/. /path/to/your/project/
```

Open the project in Zed. If the worktree is not trusted yet, trust it so Zed
loads project-local skills. Then open the Agent Panel and ask:
*"Help me set up and test Zero."*

If the project already has `.zed/settings.json`, merge the `context_servers`
and `agent.tool_permissions` entries from `dist/zero-zed/.zed/settings.json`
instead of overwriting the file.

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-zed.sh
cp -R dist/zero-zed/. /path/to/your/project/
```

Then open the project in Zed and ask the native Agent: *"Help me set up and
test Zero."*

## Staying up to date

Zed does not currently provide lifecycle hooks for this adapter. To update Zero,
re-run:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-zed.sh
cp -R dist/zero-zed/. /path/to/your/project/
```
