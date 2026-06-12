# zero-gemini (overlay — not directly installable)

This directory is **not** a complete Gemini CLI extension on its own. It holds only the
two Gemini-specific files:

- `gemini-extension.json` — the Gemini manifest (declares the Zero MCP connector)
- `hooks/hooks.json` — Gemini hook wiring (`SessionStart`, `BeforeAgent`; `${extensionPath}`; ms timeouts)

The `zero` skill and the `ensure-runner.sh` / `zero-context.sh` hook scripts are **not**
copied here — they live once in [`../zero/`](../zero/) (shared with the Codex and Claude
Code plugins) so the three hosts can't drift. User-facing install instructions are in the
[Gemini CLI guide](../../guides/gemini-cli.md).

## How the extension is built

Gemini needs `gemini-extension.json` at the extension root and auto-discovers
`hooks/hooks.json`, whose event names and output schema differ from Claude's — so Gemini
can't point at the shared `plugins/zero/` directory directly. `scripts/build-gemini.sh`
assembles the installable extension by combining this overlay with the shared skill and
hook scripts:

```
plugins/zero-gemini/                      # this overlay
  ├── gemini-extension.json              # Gemini manifest (declares the Zero MCP connector)
  └── hooks/hooks.json                   # Gemini hook wiring

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

The shared hook scripts run unchanged on Gemini: its hook-output parser reads
`hookSpecificOutput.additionalContext` by key and ignores the extra `hookEventName`
field that Claude/Codex emit.

## Installing from a local checkout

No release needed — handy for development. This overlay is not installable by itself, so
install the built `dist/zero-gemini/`:

```bash
./scripts/build-gemini.sh
gemini extensions install ./dist/zero-gemini
# or, for a live-linked dev install:
gemini extensions link ./dist/zero-gemini
```

## Shipping an update

A git-URL install expects `gemini-extension.json` at the *root* of what it installs — but
this is a monorepo whose root isn't an extension. To bridge that,
`.github/workflows/release-gemini.yml` auto-publishes a GitHub Release: on each push to
`main` it reads the `version` from `gemini-extension.json` and, if no release exists for
it yet, runs `scripts/build-gemini.sh` and publishes that version as a release with a
single `zero-gemini.tar.gz` asset (manifest at the archive root), marked **Latest**.
Gemini's installer downloads that asset.

To ship an update, bump `version` in `gemini-extension.json` and merge to `main` — the
release is cut automatically. A merge that doesn't change the version is a no-op, so
content-only changes (skill, hook scripts) ship only when you bump the version.

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

There is **no auto-approve hook in this overlay.** A Gemini `BeforeTool` hook's
`decision: "allow"` is inert (hooks can only escalate-to-`ask` or `block`/`deny`), and
Gemini deliberately strips `allow` rules from extension-bundled policies for security —
an extension cannot auto-approve its own commands. Users who want fewer prompts can add
a **user** policy themselves — create `~/.gemini/policies/zero.toml` with:

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

This never auto-approves `fetch` (spends money) or `wallet` (manages funds) — those
still prompt.

Gemini is also **not swept by the plugin's daily background refresh** (the sweep in
`ensure-runner.sh` covers Claude Code and Codex): `gemini extensions update` re-prompts
for interactive consent whenever an update changes hooks/skills/MCP, by design with no
consent-skipping flag, and a background hook auto-answering a security prompt would be a
consent bypass. Installs rely on Gemini's native `--auto-update` instead.
