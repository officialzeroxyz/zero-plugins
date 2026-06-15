# Zero for Warp

How to install Zero in Warp and keep it up to date.

## Install

### Inside Warp

Warp does not have an in-session plugin installer for local skills. Install
Zero from the terminal, then restart Warp.

To add only the Zero MCP server through Warp's MCP UI, paste this JSON:

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

First install the Zero runner:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Then, from the root of the project where you use Warp:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-warp.sh
cp -R /tmp/zero-plugins/dist/zero-warp/. .
```

Restart Warp. The Zero skill is available to the agent and can also be invoked
as `/zero`. Then ask Warp: *"Help me set up and test Zero."* It walks you
through signing in.

## Staying up to date

- To update the Zero runner, rerun:

  ```bash
  curl -fsSL https://zero.xyz/install.sh | bash
  ```

- To update the project files, rerun the terminal install commands from this
  guide.
