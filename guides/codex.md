# Zero for Codex

How to install the Zero plugin in Codex, what it supports there, and how it
stays up to date.

## Install

Inside Codex, run:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

That's it. The plugin's `SessionStart` hook provisions the Zero runner
automatically — then ask Codex to *"help me set up and test Zero"* and it
walks you through signing in.

## What's supported

The Codex plugin is backed by the same `plugins/zero/` directory as the Claude
Code plugin — same skill, same hook scripts:

| Component | Status | What it does |
|---|---|---|
| `zero` skill | ✅ | Teaches the agent the search → call → review loop |
| `SessionStart` hook | ✅ | Provisions the `@zeroxyz/cli` runner each session and puts `zero` on PATH |
| `UserPromptSubmit` hook | ✅ | Reminds the agent each turn that Zero is available |
| `PreToolUse` hook | ✅ | Auto-approves the runner's own read-only commands, so searches don't prompt |
| MCP connector | ❌ | Deliberately omitted — see below |

**Why no MCP connector?** The connector's one hard job is authenticating in
ephemeral sandboxes. The Codex surfaces that load plugins (the app and the
CLI) are persistent machines where the runner handles auth, while Codex cloud
loads neither plugins nor MCP — so the connector would have nothing to do.
Everything it offers is also available through the runner.

## Staying up to date

Updates are automatic, on two cadences:

- **The CLI runner** (`@zeroxyz/cli`) is re-resolved against npm by the
  `SessionStart` hook — a new release reaches you on your next session.
- **The plugin itself** (skill, hooks, manifest) is refreshed once a day, in
  the background, by the same hook. It goes through Codex's own plugin
  manager — `codex plugin marketplace upgrade zero-plugins` followed by
  `codex plugin add zero@zero-plugins` — never by writing into host-owned
  directories. The update applies the next time you start Codex.

Set `ZERO_PLUGIN_AUTOUPDATE=0` to opt out of the daily plugin refresh.

## Shared state across hosts

Claude Code, Codex, and Gemini CLI installs all share one login
(`~/.zero/config.json`) and one runtime (`~/.zero/runtime`) — sign in once and
every host on the machine is signed in. The daily plugin refresh likewise
sweeps every Zero install on the machine, whichever host started the session.
