# Zero for Claude on the web (claude.ai) & Claude Cowork

How to install the Zero plugin in the Claude app — web, desktop, or mobile,
they're all the same product — and in Claude Cowork. Everything here is clicks
in the Claude UI; no terminal involved.

> Using Claude Code (the CLI) instead? See the
> [Claude Code guide](claude-code.md).

## Install the plugin

1. Open [claude.ai/customize](https://claude.ai/customize) — in Claude Cowork,
   open the **Customize** tab instead.
2. Click **Browse plugins**.
3. Open the **Personal** tab and click the **+** icon.
4. Click **Add marketplace**, then select **Add from a repository**.
5. Paste `officialzeroxyz/zero-plugins`, select it from the dropdown, and
   click **Sync**.
6. After the sync completes, the Zero plugin appears in the list — click its
   **+** icon to install it.

## Connect your Zero account

1. Click the settings gear.
2. In the left pane, under **Zero**, click **Connectors**, then click
   **Install** on the Zero connector.
3. Click **Add** in the modal.
4. Click **Connect** and sign in to Zero.
5. *(Recommended)* Set Zero's tools to **Always allow**, so Claude can use
   Zero without approving every call.

## Try it

Open a new session and ask: *"Help me set up and test Zero."*

## Notes

- **How this differs from the CLI hosts.** Claude Code, Codex, and Gemini CLI
  run on a persistent machine where a CLI runner handles Zero calls and
  sign-in. Claude's chat sandboxes are ephemeral and typically have no network
  access to `zero.xyz`, so here the **Zero MCP connector** does that job
  instead — it's what the account connection above sets up.
- **Network allowlists.** If your environment blocks requests to `zero.xyz`
  after install, allow `zero.xyz` and `*.zero.xyz` in your network or
  connector settings.
