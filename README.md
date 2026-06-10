# zero-plugins

Official Zero plugins — discover and pay for AI capabilities from any agent.

Zero is a search engine and payment layer for AI agents: discover external paid
capabilities (x402 / MPP) — image/video/audio generation, web scraping, data
enrichment, real-time data, messaging — call them, and pay per use with a wallet.
No per-service signup.

## Status

This repo is being built up iteratively, one carefully reviewed PR at a time.
Today it ships the **Codex**, **Claude Code**, and **Gemini CLI** plugins.

Codex and Claude Code are both backed by the same `plugins/zero/` directory:

```
.agents/plugins/marketplace.json        # Codex marketplace catalog
.claude-plugin/marketplace.json         # Claude Code marketplace catalog
plugins/zero/
  ├── .codex-plugin/plugin.json          # Codex manifest (declares skills, mcp, hooks)
  ├── .claude-plugin/plugin.json         # Claude Code manifest (inline mcp; skills/hooks auto-discovered)
  ├── .mcp.json                          # Zero MCP connector (Codex; flattened) → https://mcp.zero.xyz
  ├── skills/zero/SKILL.md               # the 'zero' skill — runner, auth, the search→call→review loop
  └── hooks/
      ├── hooks.json                     # hook declarations
      ├── ensure-runner.sh               # SessionStart: provisions the @zeroxyz/cli runner
      ├── zero-context.sh                # UserPromptSubmit: injects a short "Zero is available" reminder
      └── auto-approve-zero.sh           # PreToolUse: auto-approves the runner's own commands
```

Both hosts share one login via `~/.zero`. The Claude manifest declares its MCP
server inline (Claude Code auto-discovers `skills/` and `hooks/hooks.json`), so
the Codex-flattened `.mcp.json` is left untouched.

Gemini CLI is delivered as a separate **extension**, but it reuses the shared
`plugins/zero/` content rather than copying it. Gemini needs `gemini-extension.json` at
the extension root and auto-discovers `hooks/hooks.json`, whose **event names and output
schema differ** from Claude's (see below) — so it can't point at `plugins/zero/` directly.
Instead, `plugins/zero-gemini/` is a thin **overlay** of just the two Gemini-specific
files, and `scripts/build-gemini.sh` assembles the installable extension by combining that
overlay with the shared skill and hook scripts:

```
plugins/zero-gemini/                      # Gemini overlay (NOT directly installable — see its README)
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

The shared `SKILL.md`, `ensure-runner.sh`, and `zero-context.sh` are **byte-identical**
across all three hosts — they live once in `plugins/zero/` and are never copied into the
repo, so they can't drift. The hook scripts run unchanged on Gemini because its
hook-output parser reads `hookSpecificOutput.additionalContext` by key and ignores the
extra `hookEventName` field that Claude/Codex emit. Only the manifest and `hooks.json`
(different event names) are genuinely Gemini-specific.

All three hosts share one login via `~/.zero/config.json` and one runtime under
`~/.zero/runtime`.

### How Gemini CLI differs from Claude Code

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

Notably, the hook *scripts* don't differ. Both hosts read context injection from
`hookSpecificOutput.additionalContext`; Claude also expects a `hookEventName` sibling,
which Gemini's (schema-less) parser simply ignores. So the shared `ensure-runner.sh` and
`zero-context.sh` emit the Claude-shaped JSON and work on Gemini unchanged — only the
`hooks.json` that wires them to events (and the manifest) is Gemini-specific.

There is **no auto-approve hook for Gemini.** A Gemini `BeforeTool` hook's
`decision: "allow"` is inert (hooks can only escalate-to-`ask` or `block`/`deny`), and
Gemini deliberately **strips `allow` rules from extension-bundled policies** for security.
So an extension cannot auto-approve its own commands (this is why the overlay has no
`auto-approve` hook). Auto-approval is the user's call — see the optional policy under
"Install in Gemini CLI" below.

Install in Claude Code:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Install in Codex:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Install in Gemini CLI:

```
gemini extensions install https://github.com/officialzeroxyz/zero-plugins
```

Gemini doesn't read the Codex/Claude marketplace catalogs, and a git-URL install expects
the `gemini-extension.json` at the *root* of what it installs — but this is a monorepo
whose root isn't an extension. To bridge that, `.github/workflows/release-gemini.yml`
auto-publishes a GitHub Release: on each push to `main` it reads the `version` from
`plugins/zero-gemini/gemini-extension.json` and, if no release exists for it yet, runs
`scripts/build-gemini.sh` and publishes that version as a release with a single
`zero-gemini.tar.gz` asset (manifest at the archive root), marked **Latest**. Gemini's
installer downloads that asset, so the one-liner above works once the release lands.

To ship an update, bump `version` in `plugins/zero-gemini/gemini-extension.json` and merge
to `main` — the release is cut automatically. A merge that doesn't change the version is a
no-op, so content-only changes (skill, hook scripts) ship only when you bump the version.

From a local checkout (no release needed — handy for development), assemble the extension
with the build script and install the result. `plugins/zero-gemini/` itself is only an
overlay, so install the built `dist/zero-gemini/`, not the overlay:

```
git clone https://github.com/officialzeroxyz/zero-plugins
cd zero-plugins
./scripts/build-gemini.sh
gemini extensions install ./dist/zero-gemini
# or, for a live-linked dev install:
gemini extensions link ./dist/zero-gemini
```

Restart Gemini CLI; the SessionStart hook provisions the runner and the `zero` skill
becomes available.

Optionally, to skip the confirmation prompt on the runner's read-only commands, add a
**user** policy (extensions can't auto-approve — Gemini strips extension `allow` rules):
create `~/.gemini/policies/zero.toml` with

```toml
# commandRegex is anchored at the start of the command string, so allow an optional
# path prefix — the runner is invoked by absolute path (e.g. ~/.zero/runtime/bin/zero).
[[rule]]
name = "auto-allow zero read-only subcommands"
toolName = "run_shell_command"
commandRegex = "(.*/)?zero (search|get|review|runs)\\b"
decision = "allow"
priority = 100
```

This never auto-approves `zero fetch` (spends money) or `zero wallet` (manages funds) —
those still prompt.

Additional hosts (Cursor) will land in subsequent PRs.
