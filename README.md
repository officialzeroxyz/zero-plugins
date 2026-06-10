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

Gemini CLI is a separate, self-contained **extension** under `plugins/zero-gemini/`.
It can't share `plugins/zero/`: Gemini auto-discovers `hooks/hooks.json` at the
extension root just like Claude, but its hook **event names and output schema differ**
(see below), so the two would collide. The skill and the runner-provisioning logic are
the same; only the host-specific hook wiring is re-expressed for Gemini.

```
plugins/zero-gemini/
  ├── gemini-extension.json              # Gemini manifest (declares mcpServers; skills/hooks auto-discovered)
  ├── skills/zero/SKILL.md               # the 'zero' skill (Gemini variant — runner is announced by path, not $ZERO_RUNNER)
  └── hooks/
      ├── hooks.json                     # hook declarations (Gemini events; ${extensionPath}; ms timeouts)
      ├── ensure-runner.sh               # SessionStart: provisions the @zeroxyz/cli runner
      └── zero-context.sh                # BeforeAgent: injects a short "Zero is available" reminder

.github/workflows/release-gemini.yml     # packages plugins/zero-gemini/ as a release asset for git-URL installs
```

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
| Context-injection output | `hookSpecificOutput.{hookEventName, additionalContext}` | `hookSpecificOutput.additionalContext` |
| Per-session env var | written to `$CLAUDE_ENV_FILE` (e.g. `ZERO_RUNNER`) | **no equivalent** — the runner is announced by absolute path instead |

There is **no auto-approve hook for Gemini.** A Gemini `BeforeTool` hook's
`decision: "allow"` is inert (hooks can only escalate-to-`ask` or `block`/`deny`), and
Gemini deliberately **strips `allow` rules from extension-bundled policies** for security.
So an extension cannot auto-approve its own commands. Auto-approval is the user's call —
see the optional policy under "Install in Gemini CLI" below.

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
whose root isn't an extension. To bridge that, a release workflow
(`.github/workflows/release-gemini.yml`) packages `plugins/zero-gemini/` into a single
`zero-gemini.tar.gz` (manifest at the archive root) and attaches it to each GitHub
Release; Gemini's installer downloads that asset. So the one-liner above works against any
**published release**.

From a local checkout (no release needed — handy for development), point the installer
straight at the extension subdirectory, which *is* a valid extension root:

```
git clone https://github.com/officialzeroxyz/zero-plugins
gemini extensions install ./zero-plugins/plugins/zero-gemini
# or, for a live-linked dev install:
gemini extensions link ./zero-plugins/plugins/zero-gemini
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
