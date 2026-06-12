# Zero for Claude Code Desktop

How to install Zero in the Claude Code desktop app (the **Code** tab of the
Claude app on Mac and Windows).

> Using the Claude Code CLI in a terminal instead? See the
> [Claude Code CLI guide](claude-code.md). Using Claude on the web or your
> phone? See the [claude.ai guide](claude-ai.md).

## Install

The desktop app and the CLI share one configuration, so a plugin installed in
one is installed in both. Adding a new plugin source isn't part of the
desktop UI yet, so step 1 happens in a terminal:

1. **Add the Zero marketplace.** Open a terminal and run:

   ```bash
   claude plugin marketplace add officialzeroxyz/zero-plugins
   ```

2. **Install the plugin.** Either run this in the same terminal:

   ```bash
   claude plugin install zero@zero-plugins
   ```

   or, in the desktop app, click the **+** button next to the prompt box,
   choose **Plugins** → **Add plugin**, and install **Zero** from the plugin
   browser.

3. **Start a new session** in the app, then ask Claude: *"Help me set up and
   test Zero."* It walks you through signing in.

## Good to know

- **Slash commands like `/plugin` are CLI-only.** The desktop app manages
  plugins through the **+** → **Plugins** menu instead.
- **Updates are automatic.** Zero keeps itself up to date in the background;
  updates apply the next time you start the app.
- **Sign in once.** Zero installs in Claude Code, Codex, and Gemini CLI on
  the same computer share one account.
