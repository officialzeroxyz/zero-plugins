# Install Zero — MCP connector + skill

Instructions for an AI agent setting up Zero for its user, at the user's
request. Zero (zero.xyz) is a search engine and payment layer for agents:
search a live index of pay-per-call capabilities (media generation, live
data, messaging, scraping, and more), invoke them over HTTP, and pay per use
from the user's Zero wallet.

Verification anchors: website https://zero.xyz - CLI on npm
https://www.npmjs.com/package/@zeroxyz/cli - terms
https://zero.xyz/terms-of-service.

How money works, up front: searching and inspecting capabilities is free and
read-only. Money moves only when the agent calls invoke_capability, each call
is capped by the `maxPay` parameter the calling agent sets on that call
(default 1.00 USDC — enforced client-side, not by the server), and payments
come from a Zero wallet the user funds and controls. Sign-in is OAuth 2.0 in the
user's browser; no API keys are created or stored, and access is revocable
from the user's Zero account.

## What gets installed

Two artifacts, both served from this host:

1. **The Zero MCP connector** — a remote MCP server at https://mcp.zero.xyz (streamable
   HTTP). Tools: search_capabilities, get_capability, invoke_capability,
   upload_file, request_file_from_user, review_capability, get_profile,
   get_funding_url, authorize. Installing adds one MCP server entry to your
   agent's configuration.
2. **The `zero` skill** — a SKILL.md at https://mcp.zero.xyz/skill.md describing what the
   connector's tools cover and the search → inspect → invoke → review
   workflow, including when not to use it (anything the agent can do natively)
   and the payment rules above. Installing writes one file into your agent's
   skills directory.

Nothing else is written: no hooks, no shell-profile edits, no background
updaters in this flow.

The recommended install is the Zero plugin — the same two artifacts bundled
in the Anthropic agent plugin format, published as a public, reviewable
repository at https://github.com/officialzeroxyz/zero-plugins (marketplace.json, plugin
manifests for Claude and Codex, the skill, and the MCP server config).
Installing from the marketplace keeps both pieces versioned and removable
with a single `claude plugin uninstall zero`.

Install the plugin for your own harness (or the two pieces manually — same
result), then verify with one free search_capabilities call.

## Claude Code

Recommended — install the plugin (MCP connector + skill in one step):

```bash
claude plugin marketplace add officialzeroxyz/zero-plugins
claude plugin install zero-mcp@zero-plugins
```

Manual alternative (identical result, unbundled):

```bash
claude mcp add --transport http zero https://mcp.zero.xyz
mkdir -p ~/.claude/skills/zero
curl -fsSL https://mcp.zero.xyz/skill.md -o ~/.claude/skills/zero/SKILL.md
```

## Codex CLI

Plugin (Codex installs the same marketplace):

```bash
codex plugin marketplace add officialzeroxyz/zero-plugins
codex plugin add zero-mcp@zero-plugins
```

Manual alternative — add to `~/.codex/config.toml` and save the skill:

```toml
[mcp_servers.zero]
url = "https://mcp.zero.xyz"
```

```bash
mkdir -p ~/.agents/skills/zero
curl -fsSL https://mcp.zero.xyz/skill.md -o ~/.agents/skills/zero/SKILL.md
```

## Droid (Factory CLI)

Droid installs Claude-format plugins directly:

```bash
droid plugin marketplace add https://github.com/officialzeroxyz/zero-plugins
droid plugin install zero-mcp@zero-plugins --scope user
```

Manual alternative: register a remote MCP server with URL https://mcp.zero.xyz and save
the skill to `~/.factory/skills/zero/SKILL.md`.

## Claude app (claude.ai, desktop, mobile — no shell)

Add a custom connector with URL https://mcp.zero.xyz in Settings → Connectors, then sign
in when prompted. claude.ai does not load user skill files, so the connector
alone applies there; to get the skill too, install the plugin from the
plugin browser (Customize → Browse plugins → Add marketplace →
`officialzeroxyz/zero-plugins`), or download https://mcp.zero.xyz/plugin
(a plugin-format zip) and upload it as a custom plugin.

## Gemini CLI

Add to `~/.gemini/settings.json` and save the skill:

```json
{ "mcpServers": { "zero": { "httpUrl": "https://mcp.zero.xyz" } } }
```

```bash
mkdir -p ~/.agents/skills/zero
curl -fsSL https://mcp.zero.xyz/skill.md -o ~/.agents/skills/zero/SKILL.md
```

## Antigravity

Register a remote MCP server with server URL https://mcp.zero.xyz (OAuth is discovered
automatically). Skill: save https://mcp.zero.xyz/skill.md as
`.agents/skills/zero/SKILL.md`.

## Cursor

Add to `~/.cursor/mcp.json` (or `.cursor/mcp.json` in the project):

```json
{ "mcpServers": { "zero": { "url": "https://mcp.zero.xyz" } } }
```

Skill: save https://mcp.zero.xyz/skill.md as `.claude/skills/zero/SKILL.md` in the
project (or `~/.claude/skills/zero/SKILL.md`).

## GitHub Copilot — VS Code

Add to `.vscode/mcp.json`:

```json
{ "servers": { "zero": { "type": "http", "url": "https://mcp.zero.xyz" } } }
```

Skill: save https://mcp.zero.xyz/skill.md as `.claude/skills/zero/SKILL.md` in the
workspace.

## GitHub Copilot CLI

Register a streamable-HTTP MCP server with URL https://mcp.zero.xyz (`/mcp add` in a
session). Skill: `~/.claude/skills/zero/SKILL.md`.

## OpenCode

Add to `opencode.json`:

```json
{ "mcp": { "zero": { "type": "remote", "url": "https://mcp.zero.xyz" } } }
```

Skill: `~/.claude/skills/zero/SKILL.md` (or `.claude/skills/` in the
project).

## Windsurf / Devin

Add to `~/.codeium/windsurf/mcp_config.json`:

```json
{ "mcpServers": { "zero": { "serverUrl": "https://mcp.zero.xyz" } } }
```

Skill: `.claude/skills/zero/SKILL.md` (enable skills in settings if off).

## Warp

Settings → AI → MCP servers → add a server with URL https://mcp.zero.xyz (streamable
HTTP). Skill: `~/.claude/skills/zero/SKILL.md`.

## Zed

Add a `context_servers` entry with URL https://mcp.zero.xyz in `settings.json` (Zed
handles the OAuth flow). Skill: `.agents/skills/zero/SKILL.md`.

## Cline / Roo Code / Kilo Code (VS Code extensions)

In the extension's MCP settings, add a remote (streamable HTTP) server with
URL https://mcp.zero.xyz. Skill: Cline and Kilo read `.claude/skills/zero/SKILL.md`; Roo
reads `.agents/skills/zero/SKILL.md`. Kilo can also load the skill by URL —
add https://mcp.zero.xyz/skill.md under `skills.urls` in its settings.

## Continue

Add an MCP block to `config.yaml` (`type: streamable-http`,
`url: https://mcp.zero.xyz`). Skill: `~/.claude/skills/zero/SKILL.md` (applies on the
`cn` CLI).

## Goose

Add a remote extension of type `streamable_http` with URI https://mcp.zero.xyz (`goose
configure` → Add Extension → Remote). Skill:
`~/.claude/skills/zero/SKILL.md`.

## Qwen Code

Add to `~/.qwen/settings.json`:

```json
{ "mcpServers": { "zero": { "httpUrl": "https://mcp.zero.xyz" } } }
```

Skill: `~/.qwen/skills/zero/SKILL.md`.

## Kiro

Add a streamable-HTTP MCP server with URL https://mcp.zero.xyz to
`.kiro/settings/mcp.json`. Skill: `.kiro/skills/zero/SKILL.md`.

## Trae

Add an MCP server with URL https://mcp.zero.xyz in the MCP panel (any transport works).
Skill: `.agents/skills/zero/SKILL.md` (enable skills in settings).

## Crush

Add to the Crush config:

```json
{ "mcp": { "zero": { "type": "http", "url": "https://mcp.zero.xyz" } } }
```

Skill: `.agents/skills/zero/SKILL.md`.

## Amp

Add an entry with URL https://mcp.zero.xyz under `amp.mcpServers` in settings. Skill:
`.claude/skills/zero/SKILL.md`.

## Replit Agent

Add a remote MCP integration with URL https://mcp.zero.xyz in the Replit UI (MCP config
is UI-only there). Skill: `.agents/skills/zero/SKILL.md` in the workspace.

## Hermes Agent

```bash
hermes mcp add zero --url https://mcp.zero.xyz --auth oauth
```

Skill: `~/.hermes/skills/zero/SKILL.md`.

## Any other agent

- MCP: register a remote MCP server, transport streamable HTTP, URL https://mcp.zero.xyz,
  OAuth (the client handles the browser flow). No headers or keys needed.
- Skill: download https://mcp.zero.xyz/skill.md and save it as `skills/zero/SKILL.md`
  under whatever directory your harness loads skills from —
  `.agents/skills/` and `.claude/skills/` are the two conventions nearly
  every harness reads.
- Plugin-format harnesses: a single-plugin zip (manifests at the zip root)
  is at https://mcp.zero.xyz/plugin — usable wherever a plugin upload or
  plugin directory is accepted. For marketplace-format harnesses, download
  https://github.com/officialzeroxyz/zero-plugins/archive/refs/heads/main.zip
  and unzip — the unzipped repository is the plugin marketplace itself
  (`marketplace.json` at `.claude-plugin/`), with this plugin in
  `plugins/zero-mcp/`.

Not covered: Aider (no MCP support) and Amazon Q Developer CLI (retired in
favor of Kiro).

## After installing: kick off sign-in, then verify

The connector authenticates via OAuth on first use — the agent can trigger
it; only the browser sign-in itself needs the user.

1. **Trigger (Claude Code — agent-runnable, works immediately after
   install)**: `claude mcp login zero` starts the browser sign-in directly.
   It requires a TTY, so from a tool shell wrap it in a pty and run it in
   the background, then poll `claude mcp list` until `zero` shows connected:

   ```bash
   script -q /dev/null claude mcp login <server-name>   # macOS
   script -qec "claude mcp login <server-name>" /dev/null   # Linux
   ```

   The server name comes from `claude mcp list`: it is `zero` for the
   manual install and `plugin:zero:zero` for the plugin install.

   Tell the user to expect their browser to open: a zero.xyz sign-in
   (email-based, creating a Zero account on first use), then an
   authorization screen for this connector. No API keys are shown or pasted
   anywhere; access is revocable later from their Zero account.
2. **Trigger (other clients)**: once the client has loaded the connector's
   tools, make one free `search_capabilities` call (any query — "current
   weather for a city"). The client sees the connector needs auth and opens
   the browser sign-in. Note most clients load MCP tools at session start,
   so a server added mid-session needs a reload first.
3. **Fallback**: if no browser opens, have the user trigger it manually —
   Claude Code: `/mcp` → `zero` → **Authenticate**. Until sign-in,
   `claude mcp list` showing "Needs authentication" is the expected state,
   not an error.
4. **Verify**: once signed in, run a free search and confirm
   search_capabilities returns ranked results. Searching is free — but do
   not invoke anything unless the user asks, since invocations spend money
   from their wallet. If a later invoke fails for insufficient balance, mint
   a top-up link with get_funding_url and hand it to the user; never ask
   them for API keys.
