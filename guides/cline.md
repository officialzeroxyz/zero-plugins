# Zero for Cline

How to install Zero in Cline and keep it up to date.

## Install

### Inside Cline

Cline does not have a Zero plugin bundle for the VS Code or JetBrains
extensions. Install the project files from the terminal, then open Cline
settings and enable Skills if needed: Settings -> Features -> Enable Skills.

To add only the Zero MCP server in Cline:

1. Open the MCP Servers panel.
2. Use the Marketplace tab if Zero is listed.
3. Otherwise use the Configure or Remote Servers tab and add:

```json
{
  "mcpServers": {
    "zero": {
      "url": "https://mcp.zero.xyz",
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

Keep `autoApprove` empty unless you have reviewed a specific Zero MCP tool and
decided it is safe to run without confirmation.

### From the terminal

First install the Zero runner:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Then, from the root of the project where you use Cline:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-cline.sh
cp -R /tmp/zero-plugins/dist/zero-cline/. .
```

Cline CLI stores MCP servers in `~/.cline/mcp.json`. To merge the Zero MCP
fragment for CLI use:

```bash
mkdir -p ~/.cline
test -f ~/.cline/mcp.json || printf '{"mcpServers":{}}\n' > ~/.cline/mcp.json
tmp="$(mktemp)"
jq -s '.[0] * .[1]' ~/.cline/mcp.json .cline/zero/mcp.json > "$tmp" && mv "$tmp" ~/.cline/mcp.json
```

Restart Cline. The Zero skill is available from `.cline/skills/zero`, and the
manual workflow is available as `/zero`. Then ask Cline: *"Help me set up
and test Zero."* It walks you through signing in.

## Staying up to date

- To update the Zero runner, rerun:

  ```bash
  curl -fsSL https://zero.xyz/install.sh | bash
  ```

- To update the project files, rerun the terminal install commands from this
  guide.
