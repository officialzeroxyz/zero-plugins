# Zero for any agent (standalone installer)

How to install Zero in any agent or harness with a shell — and for humans at a
terminal — using the standalone installer, then keep it up to date.

Use this when there's no dedicated plugin for your harness (Claude Code, Codex,
Droid, and Gemini CLI have their own guides — prefer those). The installer
provisions the **same** runner the plugins use, so you end up in the same place.

## Install

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

That single command:

- provisions the Zero runner (downloading a `node` binary if one isn't found)
  and puts `zero` on your `PATH`,
- runs `zero init`, which installs the **Zero skill** and registers the **Zero
  hooks** (see [What gets installed where](#what-gets-installed-where) below).

Once it finishes, ask your agent: *"Help me set up and test Zero."* It walks
you through signing in (you approve a browser sign-in once per machine).

## What gets installed where

`zero init` writes to the directories nearly every skills-capable harness reads:

- **The Zero skill** → `~/.claude/skills/zero/` **and** `~/.agents/skills/zero/`.
  Between those two locations, almost every harness picks up the skill from one
  or the other.
- **The Zero hooks** → `~/.claude/settings.json`, for Claude-compatible hosts.
  These keep the runner provisioned and up to date and remind the agent that
  Zero is available.

All hosts share one login (`~/.zero/config.json`) and one runtime
(`~/.zero/runtime`), so you only sign in once per machine.

### Harnesses with a bespoke skills directory

If your harness reads skills from its own directory instead of `~/.claude` or
`~/.agents` (say `~/.yourharness/skills`), point `zero init` at it with
`--skills-dir`:

```bash
zero init --skills-dir ~/.yourharness/skills
```

`zero init` is idempotent, so re-running it replaces rather than duplicates —
it's safe to run again with a different `--skills-dir` to cover an additional
location.

## Staying up to date

- The Zero runner updates automatically at the start of each session.
- To refresh the skill and hooks, re-run `zero init`.

## Uninstalling

The whole install is reversible:

```bash
zero uninstall
```

---

Installing Zero for a coding agent yourself? The full agent-facing runbook —
including authentication and per-harness plugin install — is in
[agent-install.md](agent-install.md).
