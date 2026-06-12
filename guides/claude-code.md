# Zero for Claude Code

How to install the Zero plugin in Claude Code, what it supports there, and how
it stays up to date.

## Install

Inside Claude Code, run:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

That's it. The plugin's `SessionStart` hook provisions the Zero runner
automatically — then ask Claude to *"help me set up and test Zero"* and it
walks you through signing in.

> **Using Claude on the web (claude.ai) or Claude Cowork instead?** Those
> install through the plugin UI, not a shell — see the
> [claude.ai & Claude Cowork guide](claude-ai.md).

## What's supported

Claude Code is the reference platform — every part of the plugin works here:

| Component | Status | What it does |
|---|---|---|
| `zero` skill | ✅ | Teaches the agent the search → call → review loop |
| MCP connector | ✅ | Capability search and account status via `https://mcp.zero.xyz` |
| `SessionStart` hook | ✅ | Provisions the `@zeroxyz/cli` runner each session and puts `zero` on PATH |
| `UserPromptSubmit` hook | ✅ | Reminds the agent each turn that Zero is available |
| `PreToolUse` hook | ✅ | Auto-approves the runner's own read-only commands, so searches don't prompt |

Claude Code also exposes the runner's absolute path to the session as
`$ZERO_RUNNER` (written via `$CLAUDE_ENV_FILE` by the `SessionStart` hook).

## Staying up to date

Updates are automatic, on two cadences:

- **The CLI runner** (`@zeroxyz/cli`) is re-resolved against npm by the
  `SessionStart` hook — a new release reaches you on your next session.
- **The plugin itself** (skill, hooks, manifest) is refreshed once a day, in
  the background, by the same hook. It goes through Claude Code's own plugin
  manager — `claude plugin marketplace update zero-plugins` followed by
  `claude plugin update zero@zero-plugins` — never by writing into host-owned
  directories. The update applies the next time you start Claude Code.

Set `ZERO_PLUGIN_AUTOUPDATE=0` to opt out of the daily plugin refresh.

## Shared state across hosts

Claude Code, Codex, and Gemini CLI installs all share one login
(`~/.zero/config.json`) and one runtime (`~/.zero/runtime`) — sign in once and
every host on the machine is signed in. The daily plugin refresh likewise
sweeps every Zero install on the machine, whichever host started the session.

## Implementation note

The MCP connector is declared in the plugin-root `.mcp.json` using the
documented `{"mcpServers": {...}}` shape. claude.ai's plugin loader is
stricter than the CLI and silently drops the connector if the file isn't
wrapped that way — keep that shape when editing it.
