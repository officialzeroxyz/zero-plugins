# Zero for Hermes Agent

How to install Zero in Hermes Agent and keep it up to date.

Requires Hermes Agent v2026.6.19 or newer (`hermes --version`).

## Install

### From the terminal

```bash
hermes plugins install officialzeroxyz/zero-plugins/plugins/zero-hermes/hermes --force --enable
hermes mcp add zero --url https://mcp.zero.xyz --auth oauth
```

The first command installs and enables the Zero plugin (hooks, the `/zero`
command, and the Zero skill) from this repository. The second adds the Zero
MCP server (optional — the plugin's `zero` CLI covers the full flow; the MCP
server helps sessions without a shell).

Start a new Hermes session, then use `/zero` or ask Hermes:
*"Help me set up and test Zero."* It walks you through signing in.

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
