# Zero for Gemini CLI

How to install the Zero extension in Gemini CLI, what it supports there, and
how it stays up to date.

## Install

```bash
gemini extensions install https://github.com/officialzeroxyz/zero-plugins --auto-update
```

`--auto-update` keeps the extension fresh — recommended (see
[Staying up to date](#staying-up-to-date)).

Restart Gemini CLI; the `SessionStart` hook provisions the Zero runner and the
`zero` skill becomes available. Then ask Gemini to *"help me set up and test
Zero"* and it walks you through signing in.

> Gemini resolves the GitHub URL to this repo's latest published release
> archive — there's no marketplace-add step like Claude Code / Codex.

## What's supported

Zero for Gemini is the same skill and hook scripts as the Claude Code and
Codex plugins, wired up with Gemini's manifest and event names:

| Component | Status | What it does |
|---|---|---|
| `zero` skill | ✅ | Teaches the agent the search → call → review loop |
| MCP connector | ✅ | Capability search and account status via `https://mcp.zero.xyz` |
| `SessionStart` hook | ✅ | Provisions the `@zeroxyz/cli` runner each session and puts `zero` on PATH |
| `BeforeAgent` hook | ✅ | Gemini's equivalent of `UserPromptSubmit` — reminds the agent each turn that Zero is available |
| Auto-approve hook | ❌ | Not possible in Gemini — see below |

**Why no auto-approve?** A Gemini `BeforeTool` hook's `decision: "allow"` is
inert (hooks can only escalate-to-`ask` or `block`/`deny`), and Gemini
deliberately strips `allow` rules from extension-bundled policies for
security. So an extension cannot auto-approve its own commands — auto-approval
is the user's call.

### Optional: skip prompts on read-only commands

To skip the confirmation prompt on the runner's read-only commands, add a
**user** policy: create `~/.gemini/policies/zero.toml` with

```toml
# Matches how the skill invokes the runner — the resolved .../bin/zero path or
# `"$ZERO_RUNNER"` anywhere in the command, or a bare `zero` anchored to the start of
# the command (optionally after env assignments), so `zero` appearing as a mere
# argument elsewhere can't trigger an allow.
[[rule]]
name = "auto-allow zero read-only subcommands"
toolName = "run_shell_command"
commandRegex = ".*(ZERO_RUNNER\"?|/zero\"?) +(search|get|review|runs)\\b|^(\\w+=\\S+ +)*zero +(search|get|review|runs)\\b"
decision = "allow"
priority = 100
```

This never auto-approves `fetch` (spends money) or `wallet` (manages funds) —
those still prompt.

## Staying up to date

- **The CLI runner** (`@zeroxyz/cli`) is re-resolved against npm by the
  `SessionStart` hook — a new release reaches you on your next session.
- **The extension itself** updates natively through Gemini when installed with
  `--auto-update` (the install command above). Without that flag, run
  `gemini extensions update zero` yourself occasionally.

Unlike Claude Code and Codex, Gemini is **not** covered by the plugin's daily
background refresh: `gemini extensions update` re-prompts for interactive
consent whenever an update changes hooks/skills/MCP (by design, with no
consent-skipping flag), and a background hook auto-answering a security prompt
would be a consent bypass.

## Shared state across hosts

Claude Code, Codex, and Gemini CLI installs all share one login
(`~/.zero/config.json`) and one runtime (`~/.zero/runtime`) — sign in once and
every host on the machine is signed in.

## How Gemini CLI differs from Claude Code

The same concepts, renamed:

| Concern | Claude Code | Gemini CLI |
|---|---|---|
| Manifest file | `.claude-plugin/plugin.json` | `gemini-extension.json` (at the extension root) |
| Extension-root variable | `${CLAUDE_PLUGIN_ROOT}` | `${extensionPath}` (interpolated in `hooks.json` commands) |
| Remote MCP field | `{ "type": "http", "url": … }` | `{ "httpUrl": … }` |
| Prompt-submit hook | `UserPromptSubmit` | `BeforeAgent` |
| Pre-tool hook | `PreToolUse` | `BeforeTool` |
| Shell tool name | `Bash` | `run_shell_command` |
| Hook `timeout` units | seconds | **milliseconds** |
| Per-session env var | written to `$CLAUDE_ENV_FILE` (e.g. `ZERO_RUNNER`) | **no equivalent** — the runner is announced by absolute path instead |

Notably, the hook *scripts* don't differ. Both hosts read context injection
from `hookSpecificOutput.additionalContext`; Claude also expects a
`hookEventName` sibling, which Gemini's (schema-less) parser simply ignores.
So the shared `ensure-runner.sh` and `zero-context.sh` emit the Claude-shaped
JSON and work on Gemini unchanged — only the `hooks.json` that wires them to
events (and the manifest) is Gemini-specific.

## How the extension is built (contributors)

Gemini needs `gemini-extension.json` at the extension root and auto-discovers
`hooks/hooks.json`, whose event names and output schema differ from Claude's —
so Gemini can't point at the shared `plugins/zero/` directory directly.
Instead, [`plugins/zero-gemini/`](../plugins/zero-gemini/) is a thin
**overlay** of just the two Gemini-specific files, and `scripts/build-gemini.sh`
assembles the installable extension by combining that overlay with the shared
skill and hook scripts:

```
plugins/zero-gemini/                      # Gemini overlay (NOT directly installable)
  ├── gemini-extension.json              # Gemini manifest (declares the Zero MCP connector)
  └── hooks/hooks.json                   # Gemini hook wiring (SessionStart, BeforeAgent; ${extensionPath}; ms timeouts)

scripts/build-gemini.sh                   # assembles overlay + shared plugins/zero/ files → dist/zero-gemini/
.github/workflows/release-gemini.yml      # on main, auto-publishes a release for each new manifest version

dist/zero-gemini/                         # (git-ignored) the assembled, installable extension:
  ├── gemini-extension.json              #   ← plugins/zero-gemini/
  ├── skills/zero/SKILL.md               #   ← plugins/zero/        (shared, host-agnostic skill)
  └── hooks/
      ├── hooks.json                     #   ← plugins/zero-gemini/
      ├── ensure-runner.sh               #   ← plugins/zero/        (shared, unchanged)
      └── zero-context.sh                #   ← plugins/zero/        (shared, unchanged)
```

The shared `SKILL.md`, `ensure-runner.sh`, and `zero-context.sh` are
byte-identical across all three hosts — they live once in `plugins/zero/` and
are never copied into the repo, so they can't drift.

### Installing from a local checkout

No release needed — handy for development. `plugins/zero-gemini/` itself is
only an overlay, so install the built `dist/zero-gemini/`, not the overlay:

```bash
git clone https://github.com/officialzeroxyz/zero-plugins
cd zero-plugins
./scripts/build-gemini.sh
gemini extensions install ./dist/zero-gemini
# or, for a live-linked dev install:
gemini extensions link ./dist/zero-gemini
```

### Shipping an update

A git-URL install expects `gemini-extension.json` at the *root* of what it
installs — but this is a monorepo whose root isn't an extension. To bridge
that, `.github/workflows/release-gemini.yml` auto-publishes a GitHub Release:
on each push to `main` it reads the `version` from
`plugins/zero-gemini/gemini-extension.json` and, if no release exists for it
yet, runs `scripts/build-gemini.sh` and publishes that version as a release
with a single `zero-gemini.tar.gz` asset (manifest at the archive root),
marked **Latest**. Gemini's installer downloads that asset, so the one-line
install above works once the release lands.

To ship an update, bump `version` in
`plugins/zero-gemini/gemini-extension.json` and merge to `main` — the release
is cut automatically. A merge that doesn't change the version is a no-op, so
content-only changes (skill, hook scripts) ship only when you bump the
version.
