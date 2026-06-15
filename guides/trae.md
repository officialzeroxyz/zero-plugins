# Zero for Trae

How to install Zero in Trae and keep it up to date.

## Install

### Inside Trae

Install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Trae adapter from this repository, then copy it into your project:

```bash
scripts/build-trae.sh
cp -R dist/zero-trae/. /path/to/your/project/
```

Open the project in Trae, then:

1. Go to **Settings > Skills & Commands** and confirm the `zero` project skill
   is enabled.
2. Go to **Settings > MCP**, turn on project-level MCP, and confirm the Zero
   server from `.trae/mcp.json`.
3. In chat, run `/zero` or ask: *"Help me set up and test Zero."*

If you prefer a UI MCP install, open the link in
`dist/zero-trae/trae/mcp-install-link.txt` and confirm the Zero MCP server in
Trae.

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-trae.sh
cp -R dist/zero-trae/. /path/to/your/project/
```

Restart Trae, enable project-level MCP in **Settings > MCP**, then ask Trae:
*"Help me set up and test Zero."*

## Staying up to date

Trae does not currently provide plugin lifecycle hooks for this adapter. To
update Zero, re-run:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-trae.sh
cp -R dist/zero-trae/. /path/to/your/project/
```
