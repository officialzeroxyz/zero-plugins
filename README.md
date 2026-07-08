# zero-plugins

Official Zero plugins — give your AI agent the ability to discover and pay for
new capabilities.

Zero is a search engine and payment layer for AI agents. With the Zero plugin
installed, your agent can find capabilities it doesn't have built in — image,
video, and audio generation, web scraping, real-time data, messaging, and
more — call them, and pay per use from a single wallet. No per-service
signups, no API keys to manage.

## Install Zero

The recommended way to install Zero is to let your agent install it and guide
you through setup. Just paste this to your agent:

```
Help me install Zero (zero.xyz) in this agent. Zero is an agent plugin — a CLI,
a skill, and hooks — that lets you find, invoke, and pay for thousands of
external capabilities. The skill teaches you how to use the CLI, and the hooks
remind you to reach for it when a task is beyond your built-in abilities. I
understand it adds a skill and hooks to my agent config, plus a small CLI
runtime under ~/.zero — that's what I want.

Fetch the install runbook at https://zero.xyz/install.md and read it. Tell me
briefly what the setup will do, then go ahead: use this harness's plugin
manager if the runbook lists one, run the commands in my shell, and narrate as
you go. I'll approve the browser sign-in when you show me the link. Don't add
funds or buy anything — that's a separate step I'll do later if I want. If
anything seems off, stop and ask.
```

If you prefer to set up Zero manually, or your agent had issues with the
installation, use the guides below. Pick your agent:

- **[Claude Code (CLI)](guides/claude-code.md)**
- **[Claude Code Desktop](guides/claude-code-desktop.md)**
- **[Claude on the web (claude.ai) & Claude Cowork](guides/claude-ai.md)** —
  web, desktop, and mobile
- **[Codex (CLI)](guides/codex.md)**
- **[Codex app](guides/codex-app.md)**
- **[Droid](guides/droid.md)**
- **[Gemini CLI](guides/gemini-cli.md)**
- **[Anything else (standalone installer)](guides/generic.md)** — works in any
  agent with a shell (and for humans at a terminal)

These agents don't ship a plugin manager Zero can target, so they all install
through the [standalone installer](guides/generic.md) — `zero init` detects
each one and wires up its skill and hooks automatically:

[Amp](guides/generic.md) ·
[Antigravity](guides/generic.md) ·
[Cline](guides/generic.md) ·
[Continue CLI](guides/generic.md) ·
[Crush](guides/generic.md) ·
[Cursor](guides/generic.md) ·
[Devin](guides/generic.md) ·
[GitHub Copilot CLI](guides/generic.md) ·
[Goose](guides/generic.md) ·
[Hermes Agent](guides/generic.md) ·
[Kilo Code](guides/generic.md) ·
[Kiro](guides/generic.md) ·
[OpenCode](guides/generic.md) ·
[Qwen Code](guides/generic.md) ·
[Trae](guides/generic.md) ·
[Warp](guides/generic.md) ·
[Zed](guides/generic.md)

Once installed, ask your agent to *"help me set up and test Zero"* — it signs
you in and takes it from there.

## What the plugin does

Every install ships the same three ingredients:

- **The `zero` skill** — teaches the agent how to search Zero, call a
  capability, and review the result.
- **Hooks** — keep the Zero CLI runner provisioned and up to date, and remind
  the agent that Zero is available.
- **The Zero MCP connector** — capability search and account status over MCP,
  on hosts that load it.

All hosts share one login (`~/.zero/config.json`) and one runtime
(`~/.zero/runtime`) — sign in once per machine. Updates are automatic; the
per-agent guides have the details.

## How this repo is organized

One plugin, several hosts. The skill and hook scripts live exactly once in
`plugins/zero/` and are byte-identical across hosts, so they can't drift:

```
.claude-plugin/marketplace.json   # Claude Code marketplace catalog
.agents/plugins/marketplace.json  # Codex marketplace catalog
plugins/zero/                     # the shared plugin: skill + hooks (+ Claude's MCP connector)
  ├── .claude-plugin/             # Claude Code manifest
  ├── .codex-plugin/              # Codex manifest
  └── .factory-plugin/            # Droid manifest
plugins/zero-gemini/              # thin Gemini-only overlay (manifest + hook wiring)
scripts/build-gemini.sh           # assembles the installable Gemini extension into dist/
guides/                           # per-host install guides + the agent install runbook
```

Host-specific details — manifests, hook event names, packaging, and release
mechanics — live in the per-host guides.

## Status

This repo is built up iteratively, one carefully reviewed PR at a time. Today
it ships the **Claude Code**, **Codex**, **Droid**, and **Gemini CLI** plugins,
plus standalone skill-and-hooks integration (via `plugins/zero/agents.json`)
for the seventeen agents listed above; new hosts land in subsequent PRs.
