# Zero for Devin Desktop / Devin Local

How to install Zero in Devin Desktop, Cascade, and Devin Local, and keep it up
to date.

## Install

### Inside Devin Desktop / Cascade

Devin Desktop does not have an in-session plugin installer for local skills,
rules, hooks, and workflows. Install Zero from the terminal, then restart Devin
Desktop.

To add only the Zero MCP server through Cascade's MCP UI, paste this JSON:

```json
{
  "mcpServers": {
    "zero": {
      "serverUrl": "https://mcp.zero.xyz"
    }
  }
}
```

Cascade stores MCP servers in `~/.codeium/windsurf/mcp_config.json`; the
project template also includes `.windsurf/mcp_config.json` as a copyable
fragment, but you still need to add it through the MCP UI or merge it into your
user-level Cascade MCP config.

### From the terminal

First install the Zero runner. This is required for Cascade, and also gives
Devin Local the same authenticated runner used by other Zero hosts:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Then, from the root of the project where you use Devin Desktop:

```bash
rm -rf /tmp/zero-plugins
git clone --depth 1 https://github.com/officialzeroxyz/zero-plugins /tmp/zero-plugins
/tmp/zero-plugins/scripts/build-devin.sh
cp -R /tmp/zero-plugins/dist/zero-devin/. .
```

Restart Devin Desktop. Cascade gets the Zero skill through `.agents/skills/`,
an always-on Zero rule, and the manual `/zero` workflow. Devin Local / CLI gets
`.devin/config.json`, `.devin/skills/zero/SKILL.md`, and `.devin/hooks.v1.json`
for MCP, skills, and runner provisioning.

Then ask Devin Desktop or Devin Local: *"Help me set up and test Zero."* It
walks you through signing in.

## Staying up to date

- To update the Zero runner, rerun:

  ```bash
  curl -fsSL https://zero.xyz/install.sh | bash
  ```

- To update the project files, rerun the terminal install commands from this
  guide.
