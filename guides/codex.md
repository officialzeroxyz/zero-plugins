# Zero for Codex (CLI)

How to install Zero in the Codex CLI and keep it up to date.

> Using the Codex desktop app? See the [Codex app guide](codex-app.md).

## Install

Inside a Codex CLI session, run:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
/reload-plugins
```

Or, from a regular shell:

```bash
codex plugin marketplace add officialzeroxyz/zero-plugins
codex plugin add zero@zero-plugins
```

That's it — Zero sets itself up automatically. Ask Codex: *"Help me set up
and test Zero."* It walks you through signing in.

## Staying up to date

Nothing to do — updates are automatic:

- The Zero runner updates at the start of each session.
- The plugin itself checks for updates once a day, in the background, and
  they apply the next time you start Codex.

To turn off the daily plugin check, set `ZERO_PLUGIN_AUTOUPDATE=0` in your
environment.
