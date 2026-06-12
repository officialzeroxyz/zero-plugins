# Zero for Claude Code Desktop

How to install Zero in the Claude Code desktop app (the **Code** tab of the
Claude app on Mac and Windows) and keep it up to date.

> Using the Claude Code CLI in a terminal instead? See the
> [Claude Code CLI guide](claude-code.md). Using Claude on the web or your
> phone? See the [claude.ai guide](claude-ai.md).

## Install

The app and the CLI share one install — if you've already added Zero in the
Claude Code CLI, it's already here too.

1. In the **Code** tab, click **Customize** in the sidebar.
2. Click the **+** next to **Personal plugins**, then choose
   **Create plugin** → **Add marketplace**.
3. Select **Add from a repository**.
4. Paste `officialzeroxyz/zero-plugins` and click **Sync**.
5. After the sync completes, the Zero plugin appears in the list — click its
   **+** icon to install it.
6. Start a new session and ask Claude: *"Help me set up and test Zero."* It
   walks you through signing in.

## Staying up to date

Nothing to do — updates are automatic:

- The Zero runner updates at the start of each session.
- The plugin itself checks for updates once a day, in the background, and
  they apply the next time you start the app.

To turn off the daily plugin check, set `ZERO_PLUGIN_AUTOUPDATE=0` in your
environment.
