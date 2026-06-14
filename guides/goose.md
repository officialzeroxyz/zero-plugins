# Zero for Goose

How to install Zero in Goose and keep it up to date.

## Install

### From the terminal

Clone the Zero plugins repository, build the Goose Open Plugin, and copy it
into Goose's user plugin directory:

```bash
git clone https://github.com/officialzeroxyz/zero-plugins.git
cd zero-plugins
./scripts/build-goose.sh
mkdir -p ~/.agents/plugins
rm -rf ~/.agents/plugins/zero
cp -R dist/zero-goose ~/.agents/plugins/zero
```

Restart Goose - Zero provisions its runner when a new session starts. Then ask
Goose: *"Help me set up and test Zero."* It walks you through signing in.

## Optional MCP connector

The Open Plugin installs the Zero skill and runner hook. Goose keeps remote MCP
extensions in its own config, so add the Zero MCP connector separately if you
want Goose to expose Zero account and authorization tools through MCP:

```yaml
# ~/.config/goose/config.yaml
extensions:
  zero:
    enabled: true
    type: streamable_http
    name: zero
    uri: https://mcp.zero.xyz
    description: Zero capability search and account authorization
```

You can also open this Goose deeplink from a browser:

```text
goose://extension?type=streamable_http&url=https%3A%2F%2Fmcp.zero.xyz&id=zero&name=Zero&description=Zero%20capability%20search%20and%20account%20authorization
```

## Staying up to date

- The Zero runner updates at the start of each Goose session.
- To update the Goose plugin files, update the checkout and copy the rebuilt
  plugin:

  ```bash
  cd zero-plugins
  git pull
  ./scripts/build-goose.sh
  rm -rf ~/.agents/plugins/zero
  cp -R dist/zero-goose ~/.agents/plugins/zero
  ```

Restart Goose after updating the plugin files.
