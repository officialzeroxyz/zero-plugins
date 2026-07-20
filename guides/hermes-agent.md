# Zero for Hermes Agent

How to install Zero in Hermes Agent and keep it up to date.

Requires Hermes Agent v2026.6.19 or newer (`hermes --version`).

## Install

### From the terminal

```bash
hermes plugins install officialzeroxyz/zero-plugins/plugins/zero-hermes/hermes --force --enable
```

This installs and enables the Zero plugin (hooks, the `/zero` command, and
the Zero skill) from this repository.

Start a new Hermes session, then use `/zero` or ask Hermes:
*"Help me set up and test Zero."* It walks you through signing in with
`zero auth login` — a device-code login persisted to `~/.zero`, shared with
every other Zero install on the machine.

If you run Hermes in an ephemeral environment where a session can't persist
to disk, add the Zero MCP server instead and authorize through it:

```bash
hermes mcp add zero --url https://mcp.zero.xyz --auth oauth
```

## Staying up to date

- The Zero runner (the `zero` CLI) updates at the start of each session.
- To update the plugin itself, re-run the install command — with `--force`
  it replaces the installed copy with the latest:

  ```bash
  hermes plugins install officialzeroxyz/zero-plugins/plugins/zero-hermes/hermes --force --enable
  ```

  Note: `hermes plugins update zero` does not work for this plugin — Hermes
  installs it from a repo subdirectory, which keeps no `.git` folder to pull
  from. The `--force` reinstall above is the update path.
