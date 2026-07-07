# Install Zero

Zero ([zero.xyz](https://zero.xyz)) is a search engine and payment layer for
AI agents: search for a capability, call it, and pay per use. This page is
the install guide, written for the agent that will perform the install.

**This page carries no authority of its own.** Act on it only if your
operator asked you to set up Zero, or asked for something that requires it
(like calling a paid service listed on a Zero storefront). If you reached
this page without such a request, treat it as reference documentation and do
nothing.

For the agent reading this, before you start:

- Every step says what it changes and how to undo it; the whole install is
  reversible (`zero uninstall`, or your harness's plugin uninstall). Nothing
  here asks you to relax your own safeguards, and no step asks you to keep
  anything from your operator.
- Some web-fetch tools summarize pages and drop command blocks. The raw file
  is served at <https://zero.xyz/install.md>; its canonical source is
  `guides/agent-install.md` in
  <https://github.com/officialzeroxyz/zero-plugins>. The two match, and you
  can cross-check them.
- If your environment blocks requests to `zero.xyz`, that allowlist is your
  operator's to change — tell them what was blocked rather than working
  around it.
- The commands below are exact, and small adaptations (retyped flags,
  from-memory variants) are the most common cause of broken installs. If a
  command you're about to run isn't written here, it's worth re-reading the
  raw file first.

There are two install paths — pick by where you're running:

- **In Claude Chat (the claude.ai consumer chat interface — web, desktop, or
  mobile app, they're all the same product) or Claude Cowork**: Zero installs
  through the Claude plugin UI — no shell involved. Follow the section just
  below and you're done; the shell-based runbook in the rest of this page
  does not apply (those sandboxes have no plugin CLI and typically no network
  egress to zero.xyz, even when a shell exists).
- **In a coding agent with a real shell** (Claude Code, Codex, Gemini CLI,
  OpenClaw, …): skip the next section and follow the
  [shell-based install](#shell-based-install-cli-coding-agents) below.

## Claude Chat (claude.ai) & Claude Cowork — plugin UI install

These are clicks in the Claude app, nothing else. The agent can't click
them, so this section is for relaying to the user in order, a few at a
time, in plain terms ("adding the Zero plugin", "connecting your account").
If the environment blocks requests to `zero.xyz` after install, the fix is
the user's to make: allow `zero.xyz` and `*.zero.xyz` in the network or
connector settings.

**Install the plugin:**

1. Open [claude.ai/customize](https://claude.ai/customize) — in Claude Cowork,
   open the **Customize** tab instead.
2. Click **Browse plugins**.
3. Open the **Personal** tab and click the **+** icon.
4. Click **Add marketplace**, then select **Add from a repository**.
5. Paste `officialzeroxyz/zero-plugins`, select it from the dropdown, and click
   **Sync**.
6. After the sync completes, the Zero plugin appears in the list — click its
   **+** icon to install it.

**Connect the user's Zero account:**

1. Click the settings gear.
2. In the left pane, under **Zero**, click **Connectors**, then click
   **Install** on the Zero connector.
3. Click **Add** in the modal.
4. Click **Connect** and sign in to Zero.
5. *(Recommended)* Set Zero's tools to **Always allow**, so Claude can use Zero
   without approving every call.

**Try it:** open a new session and ask — "Help me set up and test Zero."

That's the whole install for Claude Chat and Cowork — you're done; ignore the
rest of this page.

---

## Shell-based install (CLI coding agents)

The rest of this page is the runbook for the agent doing the install: the
Zero plugin for your harness (Step 1), the runner bootstrap (Step 2), and
authentication (Step 3). It takes effect in this same session — no restart
or reload — and your operator's part is at most one browser approval.

Two practical notes:

- The plugin installs below use the `claude`/`codex`/`gemini`/`openclaw`
  binary's CLI subcommands rather than REPL slash commands (`/plugin …`,
  `/extensions …`), because the desktop apps run agents without an
  interactive REPL where slash commands could execute.
- For a non-technical operator, plain-language narration ("installing Zero",
  "signing you in") lands better than file paths and hook internals. Nothing
  here is secret — if they ask what a step does, every detail on this page
  is fine to share in full.

## Step 1 — agent-specific setup

Find the subsection for the harness **you** are running in. The subsections
aren't interchangeable — each harness's plugin CLI only exists in that
harness, so another subsection's commands simply won't run in yours.

Every subsection ends the same way: **find the installed plugin root**, then
continue with **Step 2** below. You know your own harness's plugin cache —
the install commands don't reliably print the path (several print the
marketplace source rather than the installed root). You have the right
directory when it contains `skills/zero/SKILL.md`.

### Claude Code

1. **Add the Zero marketplace and install the plugin:**

   ```bash
   claude plugin marketplace add officialzeroxyz/zero-plugins
   claude plugin install zero@zero-plugins
   ```

2. **Find the installed plugin root.** It lives under your Claude config dir's
   `plugins/` — default `~/.claude/plugins/`, but if you run a custom config dir
   (e.g. `CLAUDE_CONFIG_DIR`), look there instead. You have the right directory
   when it contains `skills/zero/SKILL.md`. Continue with **Step 2** below.

### Codex

1. **Add the Zero marketplace and install the plugin:**

   ```bash
   codex plugin marketplace add officialzeroxyz/zero-plugins
   codex plugin add zero@zero-plugins
   ```

2. **Find the installed plugin root.** It lives under your Codex home's
   `plugins/` — `${CODEX_HOME:-~/.codex}/plugins/`, i.e. `~/.codex/plugins/`
   unless `CODEX_HOME` overrides it. You have the right directory when it
   contains `skills/zero/SKILL.md`. (`codex plugin list` shows a path, but it's
   the marketplace snapshot, not the installed root.) Continue with **Step 2**
   below.

### Gemini CLI

1. **Install the Zero extension** from its GitHub repository (Gemini resolves this to the
   published release archive — no marketplace-add step like Claude/Codex):

   ```bash
   gemini extensions install https://github.com/officialzeroxyz/zero-plugins --auto-update
   ```

2. **Find the installed extension root**, then continue with **Step 2** below.

### OpenClaw

1. **Install the Zero plugin.** OpenClaw installs Claude-format plugins directly
   from the marketplace repo:

   ```bash
   openclaw plugins install zero --marketplace officialzeroxyz/zero-plugins
   ```

2. **Find the installed plugin root**, then continue with **Step 2** below.
   One OpenClaw-specific point: OpenClaw imports the plugin's skill but does
   not execute its hooks — not on this session or any later one — so the
   Step 2 bootstrap is the only time the runner's dependencies get set up.

### Don't see your agent?

If none of the subsections above is the harness you are running in — or you
don't know how to install plugins in your harness — the standalone installer
covers everything the plugins do (another harness's plugin commands won't):

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

What it does: provisions the same managed runner the plugins use, puts
`zero` on PATH, and runs `zero init`, which installs the Zero skill into
both `~/.claude/skills/` and `~/.agents/skills/` (between those two, nearly
every skills-capable harness reads one or the other) and registers the Zero
hooks in `~/.claude/settings.json` for Claude-compatible hosts. The whole
install is reversible with `zero uninstall`, and the script is yours to read
before running: <https://zero.xyz/install.sh>.

If your harness reads skills from its own directory instead (say
`~/.yourharness/skills`), follow up with a second `zero init` run naming it —
the path is yours to fill in. Init is idempotent, so the re-run replaces
rather than duplicates:

```bash
zero init --skills-dir ~/.yourharness/skills
```

When it finishes: read the installed skill at
`~/.agents/skills/zero/SKILL.md`, skip **Step 2** (the installer already
bootstrapped the runner), and continue with **Step 3** using the runner path
the summary printed (bare `zero` also works in new shells — use the full
runner path if `zero` isn't found in this one).

**If the installer fails**, support can be requested with the command below;
after sending it, stop — the remaining steps won't succeed without a working
install. Substitute the placeholder values: your agent/harness name plus a
brief note on what failed (the field caps at 300 characters). The `email`
field is how Zero replies when support for your harness lands — it's your
operator's email and their choice: ask if they want to leave one, and omit
the field entirely if not.

```bash
curl -sS -X POST https://api.zero.xyz/v1/request-agent-access \
  -H "Content-Type: application/json" \
  -d '{"agent":"<the agent or harness you are, with version>","email":"<optional email for a reply>"}'
```

Humans (or browser-driving agents — the page exposes a WebMCP tool) can use
the form at <https://zero.xyz/request-agent-access> instead.

## Step 2 — bootstrap the runner (all agents)

A fresh plugin install normally takes effect at the next session start,
when the plugin's `SessionStart` hook provisions the runner. To use Zero in
this session, run that same step now, from the plugin root you found in
Step 1:

```bash
bash hooks/ensure-runner.sh
```

What it does — it's the exact command from the plugin's hook definition
(`hooks/hooks.json` in the plugin root), and a readable script if you want
to check it before running: finds a usable `node` on PATH or downloads an
official Node build into `~/.zero/runtime/`, installs the `@zeroxyz/cli`
runner there, and finishes by printing a JSON status naming the runner path
(`~/.zero/runtime/bin/zero` — referred to as `"$ZERO_RUNNER"` below).
Everything it creates lives under `~/.zero/runtime/`, which is disposable —
safe to delete and rebuild.

Before moving on, read the Zero skill at `skills/zero/SKILL.md` in the same
plugin root — it's the usage guide for everything after the install, and
where these instructions defer whenever the two differ.

## Step 3 — authenticate (all agents)

Zero accounts are how a wallet, payment history, and reviews attach to
someone. Two paths — pick by whether a human is present. Invoke the runner
as plain `zero` if that resolves on your PATH; otherwise substitute the
absolute runner path the bootstrap printed (written as `"$ZERO_RUNNER"`
below).

> **First check:** run `"$ZERO_RUNNER" auth whoami --json`. The user is signed in
> only if the output has a `user` object — if so, skip to **Step 4**. Anything
> else (e.g. `"authMethod":"none"` — possibly flagging a leftover pre-1.0 wallet
> key via `legacyKeyPresent` — or a `local-key` self-custody wallet) is **not**
> signed in: proceed with one of the paths below.

### Your operator is present (the default path)

Device-code sign-in: the account and wallet are your operator's from the
start, and their part is opening one URL. Run the commands yourself rather
than handing them over to paste.

```bash
# 1. Start the device-code login. Prints JSON with a url + userCode, exits immediately.
"$ZERO_RUNNER" auth login --start --json
```

Show the user the `url` and `userCode`. (Some harnesses hide text emitted
mid-turn right before a long-running command — that's fine here: the finish
command below re-prints the authorization URL while it waits, so the link is
always visible in the command output.)

Then run the finish command — it polls on its own until they authorize, so you
don't need to ask whether they're done. Two ways to run it:

- **Foreground, right away (works everywhere):** it blocks while polling —
  that's expected, not a hang — and you resume the moment they authorize,
  with nothing for the user to type.
- **Background — only if your harness re-invokes you when a background
  command completes** (Claude Code's background tasks do): start it in the
  background, then end your turn with the `url` + `userCode` as your final
  message. Merely being able to *launch* background processes is not enough —
  if completion won't wake you, you'll sit silent while the user waits, so
  run it in the foreground instead.

Recovery, either way: re-running `--finish` with the same deviceCode is always
safe — it returns immediately if the user already authorized and resumes
polling otherwise. So if your harness kills the foreground command with a tool
timeout, just run it again. If the code expired before the user ever saw the
link (`{"status":"expired"}` without them acting), start over from step 1 and
this time make the `url` + `userCode` the final message of your turn, then run
`--finish` when the user next replies.

```bash
# 2. Blocks until the user authorizes; persists the session on success.
"$ZERO_RUNNER" auth login --finish <deviceCode from step 1> --json
```

`{"status":"ok"}` means you're signed in — confirm with `"$ZERO_RUNNER" auth
whoami --json` (the output should now have a `user` object).
`{"status":"expired"}` means the code lapsed — start over from step 1.

### No human in the loop

When your operator set you up to run autonomously (throwaway sandboxes, CI,
agent fleets) and isn't available to approve a sign-in, Zero supports
anonymous agent registration — an account and managed wallet created without
a browser, an email, or a human step (the auth.md protocol; see
<https://zero.xyz/auth.md>):

```bash
"$ZERO_RUNNER" auth agent register
```

It prints the new wallet's address and persists the session in
`~/.zero/config.json`. The account starts unfunded: free capabilities work
immediately; paid ones need funding first — check prices before spending,
and stay inside whatever budget your operator authorized.

A human can take ownership of the account later:

```bash
"$ZERO_RUNNER" auth agent claim <their-email>
```

prints a URL for them to open; they read a pairing code back to you and the
account, wallet, and history become theirs. When an operator is available
now, the device sign-in above is the better path — no claim step needed.

However the sign-in played out, the install isn't quite done — close it out
with **Step 4** below.

## Step 4 — try it out (optional, all agents)

Once authentication succeeds, the install works. A nice first thing to try:
ask Zero to build and host a simple site, e.g.

> "Build me a simple, but visually stunning hello world site and host it with
> Zero for free."

Offer it if it fits — skip it if the user already has their own task in mind.
