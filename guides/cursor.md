# Zero for Cursor

How to install Zero in Cursor and keep it up to date.

## Install

### Inside Cursor

Cursor does not have an in-session plugin installer for local skills and hooks.
Install Zero from the terminal, then restart Cursor.

To add only the Zero MCP server through Cursor's UI, open the generated
`.cursor/mcp.json` file after installation or add this server manually:

```json
{
  "mcpServers": {
    "zero": {
      "url": "https://mcp.zero.xyz"
    }
  }
}
```

### From the terminal

From the root of the project where you use Cursor:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-cursor.sh
cp -R /tmp/zero-plugins/dist/zero-cursor/. .
```

Restart Cursor. Zero sets itself up automatically when a Cursor agent session
starts. Then ask Cursor: *"Help me set up and test Zero."* It walks you through
signing in.

## Staying up to date

- The Zero runner updates at the start of each Cursor agent session.
- To update the project files, rerun the terminal install commands from this
  guide.
