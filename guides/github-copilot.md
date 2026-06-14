# Zero for GitHub Copilot

How to install Zero in GitHub Copilot CLI and VS Code agent mode, and keep it
up to date.

## Install

### Inside GitHub Copilot

Inside a Copilot CLI session, run:

```
/plugin marketplace add officialzeroxyz/zero-plugins
/plugin install zero@zero-plugins
```

In VS Code, install the same plugin from the Agent Plugins view:

1. Open the Extensions view.
2. Search for `@agentPlugins`.
3. Install Zero from the `officialzeroxyz/zero-plugins` marketplace.

If Zero is not listed yet, run **Chat: Install Plugin From Source** from the
Command Palette and enter:

```
https://github.com/officialzeroxyz/zero-plugins
```

### From the terminal

```bash
copilot plugin marketplace add officialzeroxyz/zero-plugins
copilot plugin install zero@zero-plugins
```

VS Code automatically discovers plugins installed by Copilot CLI. Start a new
Copilot session, then ask: *"Help me set up and test Zero."* Copilot walks you
through signing in.

## Staying up to date

- The Zero runner updates at the start of each session.
- To update the plugin itself, run:

  ```bash
  copilot plugin update zero
  ```
