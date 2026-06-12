# Zero for Gemini CLI

How to install Zero in Gemini CLI, what it can do there, and how it stays up
to date.

## Install

```bash
gemini extensions install https://github.com/officialzeroxyz/zero-plugins --auto-update
```

Restart Gemini CLI — Zero sets itself up automatically. Then ask Gemini:
*"Help me set up and test Zero."* It walks you through signing in.

## What's supported

| Feature | Supported | What it does |
|---|---|---|
| `zero` skill | ✅ | Teaches Gemini how to find, use, and pay for capabilities |
| Zero connector (MCP) | ✅ | Lets Gemini search Zero and check your account |
| Automatic setup (`SessionStart` hook) | ✅ | Installs and updates the Zero runner each session |
| Zero reminders (`BeforeAgent` hook) | ✅ | Keeps Gemini aware that Zero is available |
| Auto-approval | ❌ | Gemini doesn't let extensions approve their own commands — see below |

### Optional: fewer permission prompts

By default, Gemini asks before each Zero command. To let Zero's read-only
commands (searching and checking results) run without a prompt, create
`~/.gemini/policies/zero.toml` with:

```toml
[[rule]]
name = "auto-allow zero read-only subcommands"
toolName = "run_shell_command"
commandRegex = ".*(ZERO_RUNNER\"?|/zero\"?) +(search|get|review|runs)\\b|^(\\w+=\\S+ +)*zero +(search|get|review|runs)\\b"
decision = "allow"
priority = 100
```

This never auto-approves anything that spends money or touches your wallet —
those always ask first.

## Staying up to date

- The Zero runner updates at the start of each session.
- The extension itself updates automatically if you installed it with
  `--auto-update` (the command above). If you didn't, run
  `gemini extensions update zero` occasionally.

## Sign in once

Zero installs in Gemini CLI, Claude Code, and Codex on the same computer
share one account — sign in once and you're signed in everywhere.
