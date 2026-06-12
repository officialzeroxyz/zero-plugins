# Zero for Claude on the web (claude.ai) & Claude Cowork

How to install Zero in the Claude app — web, desktop, or mobile, they're all
the same product — and in Claude Cowork. Everything here is clicks in the
Claude UI; no terminal involved.

> Using Claude Code instead? See the [CLI guide](claude-code.md) or the
> [desktop guide](claude-code-desktop.md).

## Turn on code execution

1. Open [claude.ai/new#settings/capabilities](https://claude.ai/new#settings/capabilities).
2. Make sure **Code execution and file creation** is turned on.
3. Make sure **Allow network egress** is turned on, and set the **Domain
   allowlist** to **All domains**.

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
