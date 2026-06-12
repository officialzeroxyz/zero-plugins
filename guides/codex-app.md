# Zero for the Codex app

How to install Zero in the Codex desktop app and keep it up to date.

> Using the Codex CLI in a terminal instead? See the
> [Codex CLI guide](codex.md).

## Install

The app and the CLI share one install — if you've already added Zero in the
Codex CLI, it's already here too.

1. Open **Plugins** in the sidebar.
2. Click the **+** button in the top-right corner and choose **Add
   marketplace**.
3. In the **Source** field, enter:

   ```
   officialzeroxyz/zero-plugins
   ```

   Leave **Git ref** and **Sparse paths** as they are, and click **Add
   marketplace**. You'll see a "zero-plugins marketplace added" confirmation.
4. A **Zero** filter now appears next to **Curated by OpenAI**. Select it,
   then click **Add plugin** on the **Zero** plugin.
5. Start a new chat and ask Codex: *"Help me set up and test Zero."* It walks
   you through signing in.

## Staying up to date

Nothing to do — updates are automatic:

- The Zero runner updates at the start of each session.
- The plugin itself checks for updates once a day, in the background, and
  they apply the next time you start Codex.

To turn off the daily plugin check, set `ZERO_PLUGIN_AUTOUPDATE=0` in your
environment.
