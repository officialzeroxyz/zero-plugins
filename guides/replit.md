# Zero for Replit Agent

How to install Zero in Replit Agent and keep it up to date.

## Install

### Inside Replit

Replit Agent uses project skills and UI-managed MCP integrations. There is no
local plugin installer, hooks file, slash-command file, or project MCP config
file.

To add the Zero MCP server:

1. Open the Replit Integrations pane.
2. If Zero is listed, click **Add to Replit** and authorize it.
3. Otherwise choose the option to add a custom MCP server and use:
   - Display name: `Zero`
   - URL: `https://mcp.zero.xyz`
   - Headers: none

Replit scans MCP tools before running them. If Replit blocks a tool, review the
blocked-tool message in Agent before continuing.

### From the terminal

First install the Zero runner in the Replit shell:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Then, from the root of the Replit project:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-replit.sh
cp -R /tmp/zero-plugins/dist/zero-replit/. .
```

The Zero skill is available from `/.agents/skills/zero`. The MCP install
payload is copied to `replit/mcp-install.json` for reference; Replit still
requires adding MCP servers through the UI or an install link.

Restart Replit Agent, then ask: *"Help me set up and test Zero."* It walks you
through signing in.

## Staying up to date

- To update the Zero runner, rerun:

  ```bash
  curl -fsSL https://zero.xyz/install.sh | bash
  ```

- To update the project files, rerun the terminal install commands from this
  guide.
