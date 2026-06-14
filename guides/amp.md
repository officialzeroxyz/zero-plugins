# Zero for Amp

How to install Zero in Amp and keep it up to date.

## Install

### From the terminal

Clone the Zero plugins repository, build the Amp package, and copy the Amp
project files into your workspace:

```bash
git clone https://github.com/officialzeroxyz/zero-plugins.git
cd zero-plugins
./scripts/build-amp.sh
cp -R dist/zero-amp/. /path/to/your/workspace/
```

From the Amp workspace, reload plugins or restart Amp:

```bash
amp plugins list
```

The Zero skill is installed at `.agents/skills/zero/`. Amp exposes skills
through its command palette, opened with `/` in the CLI. The skill also bundles
the Zero MCP connector in `.agents/skills/zero/mcp.json`, so Zero MCP tools are
only exposed when the Zero skill is loaded.

Once installed, ask Amp: *"Help me set up and test Zero."* It walks you through
signing in.

### Global install

For a user-wide install, copy the same files into Amp's global plugin and skill
locations:

```bash
git clone https://github.com/officialzeroxyz/zero-plugins.git
cd zero-plugins
./scripts/build-amp.sh
mkdir -p ~/.config/amp/plugins ~/.config/amp/zero/hooks ~/.config/agents/skills
cp dist/zero-amp/.amp/plugins/zero.ts ~/.config/amp/plugins/zero.ts
cp dist/zero-amp/.amp/zero/hooks/*.sh ~/.config/amp/zero/hooks/
rm -rf ~/.config/agents/skills/zero
cp -R dist/zero-amp/.agents/skills/zero ~/.config/agents/skills/zero
```

## Staying up to date

- The Zero runner updates when the Amp Zero plugin starts a thread session.
- To update the Amp plugin and skill files:

  ```bash
  cd zero-plugins
  git pull
  ./scripts/build-amp.sh
  cp -R dist/zero-amp/. /path/to/your/workspace/
  ```

For a global install, repeat the global copy commands above.
