# Zero for Kiro

How to install Zero in Kiro and keep it up to date.

## Install

### Inside Kiro IDE

Install the Zero Power from a local checkout:

1. Clone this repository and build the Kiro package:

   ```bash
   git clone https://github.com/officialzeroxyz/zero-plugins.git
   cd zero-plugins
   ./scripts/build-kiro.sh
   ```

2. In Kiro, open the Powers panel.
3. Choose **Add Custom Power**.
4. Choose **Import power from a folder**.
5. Select `dist/zero-kiro/power`.
6. Finish the install prompt.

Install the Zero skill so it is available as `/zero`:

```bash
mkdir -p ~/.kiro/skills
rm -rf ~/.kiro/skills/zero
cp -R dist/zero-kiro/skills/zero ~/.kiro/skills/zero
```

Install the Zero runner:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Restart Kiro, then ask: *"Help me set up and test Zero."*

### From the terminal

Build the Kiro package and copy the skill:

```bash
git clone https://github.com/officialzeroxyz/zero-plugins.git
cd zero-plugins
./scripts/build-kiro.sh
mkdir -p ~/.kiro/skills
rm -rf ~/.kiro/skills/zero
cp -R dist/zero-kiro/skills/zero ~/.kiro/skills/zero
```

Add the Zero MCP server:

```bash
kiro-cli mcp add --name zero --scope global --url https://mcp.zero.xyz --force
```

Optional: install the Kiro CLI custom-agent template with Zero prompt hooks:

```bash
mkdir -p ~/.kiro/agents ~/.kiro/zero/hooks
cp dist/zero-kiro/agents/zero.json ~/.kiro/agents/zero.json
cp dist/zero-kiro/hooks/*.sh ~/.kiro/zero/hooks/
chmod +x ~/.kiro/zero/hooks/*.sh
```

Start Kiro with that template:

```bash
kiro-cli chat --agent zero
```

Then ask: *"Help me set up and test Zero."*

## Staying up to date

- Kiro CLI updates itself automatically.
- The optional `zero` Kiro CLI agent provisions and refreshes the Zero runner
  with its `agentSpawn` hook.
- If you only installed the Kiro IDE Power, rerun the standalone installer to
  refresh the runner:

  ```bash
  curl -fsSL https://zero.xyz/install.sh | bash
  ```

- To update the Zero Kiro files:

  ```bash
  cd zero-plugins
  git pull
  ./scripts/build-kiro.sh
  rm -rf ~/.kiro/skills/zero
  cp -R dist/zero-kiro/skills/zero ~/.kiro/skills/zero
  cp dist/zero-kiro/agents/zero.json ~/.kiro/agents/zero.json
  cp dist/zero-kiro/hooks/*.sh ~/.kiro/zero/hooks/
  ```

If you installed the Power in Kiro IDE, open the Powers panel and use the
Power's update action, or re-import `dist/zero-kiro/power`.
