# Zero for Claude Code (CLI)

How to install Zero in the Claude Code CLI, what it can do there, and how it
stays up to date.

> Using the desktop app? See the
> [Claude Code Desktop guide](claude-code-desktop.md). Using Claude on the
> web or your phone? See the [claude.ai guide](claude-ai.md).

## Install

Inside a Claude Code session, run:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Or, from a regular shell:

```bash
claude plugin marketplace add officialzeroxyz/zero-plugins
claude plugin install zero@zero-plugins
```

That's it — Zero sets itself up automatically. Ask Claude: *"Help me set up
and test Zero."* It walks you through signing in.

## What's supported

Everything. Claude Code is the platform the plugin was built for:

| Feature | Supported | What it does |
|---|---|---|
| `zero` skill | ✅ | Teaches Claude how to find, use, and pay for capabilities |
| Zero connector (MCP) | ✅ | Lets Claude search Zero and check your account |
| Automatic setup (`SessionStart` hook) | ✅ | Installs and updates the Zero runner each session |
| Zero reminders (`UserPromptSubmit` hook) | ✅ | Keeps Claude aware that Zero is available |
| Auto-approval (`PreToolUse` hook) | ✅ | Zero's read-only commands run without permission prompts |

## Staying up to date

Nothing to do — updates are automatic:

- The Zero runner updates at the start of each session.
- The plugin itself checks for updates once a day, in the background, and
  they apply the next time you start Claude Code.

To turn off the daily plugin check, set `ZERO_PLUGIN_AUTOUPDATE=0` in your
environment.

## Sign in once

Zero installs in Claude Code, Codex, and Gemini CLI on the same computer
share one account — sign in once and you're signed in everywhere.
