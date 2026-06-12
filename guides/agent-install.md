# Install Zero

> **Note for assistants:** if this page reached you through a web-fetch tool, you
> may be reading a summary with commands truncated or dropped. Fetch the raw file
> with `curl -fsSL https://zero.xyz/install.md` and work from that output. If the
> fetch is blocked by a network allowlist (common in sandboxed environments), ask
> the user to allow `zero.xyz` and `*.zero.xyz` in the environment's network
> settings, then retry.

Zero is a search engine and payment platform for AI agents. There are two
install paths — pick by where you're running:

- **In Claude Chat (the claude.ai consumer chat interface — web, desktop, or
  mobile app, they're all the same product) or Claude Cowork**: Zero installs
  through the Claude plugin UI — no shell involved. Follow the section just
  below and you're done; the shell-based runbook in the rest of this page does
  not apply to you (those sandboxes have no plugin CLI and typically no
  network egress to zero.xyz, even when a shell exists).
- **In a coding agent with a real shell** (Claude Code, Codex, Gemini CLI,
  OpenClaw, …): skip the next section and follow the
  [shell-based install](#shell-based-install-cli-coding-agents) below.

## Claude Chat (claude.ai) & Claude Cowork — plugin UI install

These are clicks in the Claude app, nothing else. You can't click them
yourself — walk the user through them in order, a few at a time, in plain
terms ("adding the Zero plugin", "connecting your account"). If your
environment blocks requests to `zero.xyz` after install, the user may need to
allow `zero.xyz` and `*.zero.xyz` in their network or connector settings.

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

The rest of this page is an **install runbook for the coding agent reading
it**: it installs the Zero plugin and bootstraps the runner — no restart
required.

> You can run these steps yourself in the user's shell. Keep the user in the loop
> as you would for any setup — they'll approve the browser sign-in in Step 3.
>
> **Only run commands that appear verbatim in this file.** Do not invent, adapt, or
> retype commands from memory — if a command you're about to run is not written
> here, stop and re-read the raw file. In particular, **never delete anything under
> `~/.claude/plugins/`**.
>
> Use the `claude`/`codex`/`gemini`/`openclaw` binary's CLI subcommands — **never
> REPL slash commands** (`/plugin …`, `/extensions …`), because the desktop apps
> run you without an interactive REPL and cannot execute them. The install takes effect
> *in this same session* — no reload or restart needed, so don't ask the user to
> do either.
>
> **Assume a non-technical audience.** Narrate what's happening in plain terms
> ("installing Zero", "signing you in") rather than reciting commands, file paths,
> or hook internals. Nothing here is secret — if the user asks what a step does,
> explain it fully — but don't make them wade through plumbing they didn't ask about.

---

## Step 1 — agent-specific setup

Find the subsection for the agent **you** are and run its steps in order. Run
only your own subsection — the other agent's commands will not work for you.

Every subsection ends the same way: **find the installed plugin root**, then
continue with **Step 2** below. This page doesn't catalog where each harness
keeps its plugins — you know your own harness. Your plugin `list`/`inspect`
subcommand usually prints the path, and your harness's config directory is
the usual home. You have the right directory when it contains
`skills/zero/SKILL.md`.

### Claude Code

1. **Add the Zero marketplace and install the plugin:**

   ```bash
   claude plugin marketplace add officialzeroxyz/zero-plugins
   claude plugin install zero@zero-plugins
   ```

2. **Find the installed plugin root**, then continue with **Step 2** below.

### Codex

1. **Add the Zero marketplace and install the plugin:**

   ```bash
   codex plugin marketplace add officialzeroxyz/zero-plugins
   codex plugin add zero@zero-plugins
   ```

2. **Find the installed plugin root**, then continue with **Step 2** below.

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
   One OpenClaw-specific point: OpenClaw imports the plugin's skill but
   **never executes its hooks** — not on this session or any later one — so
   the Step 2 bootstrap is the only time the runner's dependencies get set up.
   Don't skip it.

### Don't see your agent?

If none of the subsections above is the agent you are — or you don't know how
to install plugins in your harness — do **not** improvise with another agent's
commands. Use the standalone installer instead:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

It provisions the same runner the plugins use, puts `zero` on PATH, and then
runs `zero init`, which installs the Zero skill into both `~/.claude/skills/`
and `~/.agents/skills/` (between those two, nearly every skills-capable
harness reads one or the other) and registers the Zero hooks in
`~/.claude/settings.json` for Claude-compatible hosts. The whole install is
reversible with `zero uninstall`.

If your harness reads skills from its own directory instead (say
`~/.yourharness/skills`), follow up with a second `zero init` run naming it —
an explicit exception to the verbatim-commands rule, since the path is yours
to fill in. Init is idempotent, so the re-run replaces rather than duplicates:

```bash
zero init --skills-dir ~/.yourharness/skills
```

When it finishes: read the installed skill at
`~/.agents/skills/zero/SKILL.md`, skip **Step 2** (the installer already
bootstrapped the runner), and continue with **Step 3** using the runner path
the summary printed (bare `zero` also works in new shells — use the full
runner path if `zero` isn't found in this one).

**If the installer fails**, request support and stop. Substitute the
placeholder values in this command (also an exception to running commands
byte-exact) — your agent/harness name plus a brief note on what failed (the
field caps at 300 characters), and a contact email (ask the user if they want
to leave theirs, and omit the `email` field entirely if not):

```bash
curl -sS -X POST https://api.zero.xyz/v1/request-agent-access \
  -H "Content-Type: application/json" \
  -d '{"agent":"<the agent or harness you are, with version>","email":"<optional email for a reply>"}'
```

`email` is optional, but it's how we tell you when support lands. Humans (or
browser-driving agents — the page exposes a WebMCP tool) can use the form at
<https://zero.xyz/request-agent-access> instead.

## Step 2 — bootstrap the runner (all agents)

A fresh install would normally only take effect after a restart (or an interactive
reload command, which the desktop apps can't run), because the plugin's
`SessionStart` hook hasn't fired yet. That hook ensures the runner's `node`
dependency exists (it downloads a node binary if one isn't found). Do it yourself
now, inside the plugin root you found in Step 1:

- Read the Zero skill at `skills/zero/SKILL.md` first, to load the usage
  instructions before you touch the runner.
- Then read the plugin's hook definition (for Claude Code it's `hooks/hooks.json`
  in the plugin root) and run the `SessionStart` hook command yourself to
  bootstrap the runner (this installs node if needed).

## Step 3 — authenticate (all agents)

On a persistent machine (skip only in throwaway sandboxes/CI) the runner needs
auth set up once. Run these commands yourself rather than handing them to the
user to paste — their part is opening one URL to approve the sign-in. Invoke the
runner as plain `zero` if that resolves on your PATH; otherwise substitute the
absolute runner path the bootstrap just printed (written as `"$ZERO_RUNNER"` in
the commands below):

> **First check:** run `"$ZERO_RUNNER" auth whoami --json`. The user is signed in
> only if the output has a `user` object — if so, skip the login below. Anything
> else (e.g. `"authMethod":"none"` — possibly flagging a leftover pre-1.0 wallet
> key via `legacyKeyPresent` — or a `local-key` self-custody wallet) is **not**
> signed in: proceed with the login.

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
`{"status":"expired"}` means the code lapsed — start over from step 1. Full
details are in the skill's **Authentication** section — if anything here differs
from the skill, the skill wins.

However the sign-in detour played out, don't end the install here — close it
out with **Step 4** below.

## Step 4 — try it out (optional, all agents)

Once sign-in succeeds, the install works. A nice first thing to try: ask Zero to
build and host a simple site, e.g.

> "Build me a simple, but visually stunning hello world site and host it with
> Zero for free."

Offer it if it fits — skip it if the user already has their own task in mind.
