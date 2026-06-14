# Zero for OpenCode

How to install Zero in OpenCode and keep it up to date.

## Install

### Inside OpenCode

Inside an OpenCode session, run:

```
/plugin @zeroxyz/opencode-zero
```

Start a new OpenCode session after the plugin installs.

### From the terminal

```bash
opencode plugin @zeroxyz/opencode-zero
```

Start a new OpenCode session. Zero sets itself up automatically, including the
runner, skill, MCP server, and `/zero` command. Ask OpenCode: *"Help me set up
and test Zero."* It walks you through signing in.

## Staying up to date

- The Zero runner updates at the start of each session.
- To update the OpenCode plugin itself, run:

  ```bash
  opencode plugin @zeroxyz/opencode-zero --force
  ```
