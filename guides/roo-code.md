# Zero for Roo Code

How to install Zero in Roo Code and keep it up to date.

## Install

### Inside Roo Code

Install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Roo adapter from this repository, then copy it into your project:

```bash
scripts/build-roo.sh
cp -R dist/zero-roo/. /path/to/your/project/
```

Open the project in VS Code with Roo Code installed, then:

1. Open Roo Code's MCP settings and confirm the `zero` server from
   `.roo/mcp.json`.
2. Confirm MCP servers are enabled.
3. Use `/zero` or ask Roo: *"Help me set up and test Zero."*

If Roo Code prompts to approve MCP tools, keep paid or state-changing tools
confirmation-gated. The adapter leaves `alwaysAllow` empty by default.

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-roo.sh
cp -R dist/zero-roo/. /path/to/your/project/
```

Restart VS Code if Roo does not pick up the new project files immediately, then
ask Roo: *"Help me set up and test Zero."*

## Staying up to date

Roo Code does not currently provide lifecycle hooks for this adapter. To update
Zero, re-run:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-roo.sh
cp -R dist/zero-roo/. /path/to/your/project/
```
