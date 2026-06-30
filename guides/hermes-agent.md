# Zero for Hermes Agent

How to install Zero in Hermes Agent and keep it up to date.

## Install

### Inside Hermes Agent

Install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Hermes adapter from this repository, then copy it into your Hermes
home:

```bash
scripts/build-hermes.sh
mkdir -p ~/.hermes/plugins ~/.hermes/skills
cp -R dist/zero-hermes/.hermes/plugins/zero ~/.hermes/plugins/
cp -R dist/zero-hermes/.hermes/skills/zero ~/.hermes/skills/
```

Enable the plugin and add the Zero MCP server:

```bash
hermes plugins enable zero
hermes mcp add zero --url https://mcp.zero.xyz --auth oauth
```

Start a new Hermes session, then use `/zero` or ask Hermes:
*"Help me set up and test Zero."*

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-hermes.sh
mkdir -p ~/.hermes/plugins ~/.hermes/skills
cp -R dist/zero-hermes/.hermes/plugins/zero ~/.hermes/plugins/
cp -R dist/zero-hermes/.hermes/skills/zero ~/.hermes/skills/
hermes plugins enable zero
hermes mcp add zero --url https://mcp.zero.xyz --auth oauth
```

Restart Hermes, then ask: *"Help me set up and test Zero."*

## Staying up to date

The Zero runner updates when the Hermes plugin's session-start hook runs. To
refresh the Hermes adapter files, re-run:

```bash
scripts/build-hermes.sh
cp -R dist/zero-hermes/.hermes/plugins/zero ~/.hermes/plugins/
cp -R dist/zero-hermes/.hermes/skills/zero ~/.hermes/skills/
```
