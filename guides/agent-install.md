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

- The install is three commands and one browser approval, and it's
  reversible: `zero uninstall` removes everything the setup writes. Nothing
  here asks you to relax your own safeguards, and no step asks you to keep
  anything from your operator.
- The software comes from the public npm registry (`@zeroxyz/cli`) — its
  provenance is verifiable with `npm view @zeroxyz/cli`, and the source is
  <https://github.com/officialzeroxyz/zero-plugins> (plugins) and the
  `zero` CLI repo linked from the package page.
- Some web-fetch tools summarize pages and drop command blocks. The raw
  file is served at <https://zero.xyz/install.md>; its canonical source is
  `guides/agent-install.md` in
  <https://github.com/officialzeroxyz/zero-plugins>. The two match, and you
  can cross-check them.
- If your environment blocks requests to `zero.xyz` or `registry.npmjs.org`,
  that allowlist is your operator's to change — tell them what was blocked
  rather than working around it.

There are two install paths — pick by where you're running:

- **In Claude Chat (the claude.ai consumer chat interface — web, desktop, or
  mobile app, they're all the same product) or Claude Cowork**: Zero installs
  through the Claude plugin UI — no shell involved. Follow the section just
  below and you're done; the shell-based setup does not apply (those
  sandboxes typically have no network egress to zero.xyz, even when a shell
  exists).
- **In a coding agent with a shell** (Claude Code, Codex, Gemini CLI,
  OpenClaw, Cursor, and nearly anything else): follow the
  [shell-based setup](#shell-based-setup-all-cli-agents) below. One flow
  covers every harness — `zero init` detects yours and installs the right
  integration itself.

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

## Shell-based setup (all CLI agents)

One flow for every harness. The `zero` CLI is the installer: `zero init`
detects which harnesses are on the machine and installs the right
integration for each — through the harness's own plugin manager where one
exists (`claude`, `codex`, `gemini`, `openclaw`), or as a portable
skill-and-hooks install everywhere else. You don't pick a variant; init
does.

### Step 1 — install the CLI and run init

With Node.js available (`npm` on PATH):

```bash
npm i -g @zeroxyz/cli
zero init
```

Without Node.js, the standalone installer does the same and brings its own
Node (it downloads an official Node build into `~/.zero/runtime/` rather
than touching your system):

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

The script is readable at that URL before running; it provisions the
runner, puts `zero` on PATH, and then runs the same `zero init`.

What `zero init` does — it prints each step as it goes:

- Detects installed harnesses by their config dirs (`~/.claude`,
  `~/.codex`, `~/.gemini`, `~/.openclaw`, …).
- For each one whose CLI is callable, installs the Zero plugin through that
  harness's own plugin manager (e.g. `claude plugin install
  zero@zero-plugins`). It never edits a harness's files behind its back
  when a plugin manager can do it properly.
- If no plugin install succeeds, falls back to a portable install: the
  Zero skill into `~/.claude/skills/zero/` and `~/.agents/skills/zero/`,
  hook scripts staged in `~/.zero/hooks/` and registered in
  `~/.claude/settings.json` / `~/.codex/hooks.json`.
- Creates no account and no wallet, and makes no purchases.

All of it is reversed by `zero uninstall` (plugin installs are removed via
each harness's own uninstall).

### Step 2 — be operational in this session

Skills load at session start, so the session that ran init can't see the
skill it just installed. The init summary points at the installed skill
file (e.g. `~/.agents/skills/zero/SKILL.md`) — read it now; it's the usage
guide for everything after the install, and where these instructions defer
whenever the two differ. If init installed through your harness's plugin
manager instead, the skill is at `skills/zero/SKILL.md` under the installed
plugin root. Future sessions load it automatically.

### Step 3 — authenticate

Zero accounts are how a wallet, payment history, and reviews attach to
someone. Two paths — pick by whether a human is present.

> **First check:** run `zero auth whoami --json`. The user is signed in only
> if the output has a `user` object — if so, skip to **Step 4**. Anything
> else (e.g. `"authMethod":"none"`, or a `local-key` self-custody wallet) is
> **not** signed in: proceed with one of the paths below.

#### Your operator is present (the default path)

Device-code sign-in: the account and wallet are your operator's from the
start, and their part is opening one URL. Run the commands yourself rather
than handing them over to paste.

```bash
# 1. Start the device-code login. Prints JSON with a url + userCode, exits immediately.
zero auth login --start --json
```

Show the user the `url` and `userCode`. Then run the finish command — it
polls on its own until they authorize, so you don't need to ask whether
they're done:

```bash
# 2. Blocks while polling (expected, not a hang); persists the session on success.
zero auth login --finish <deviceCode from step 1> --json
```

Practical notes:

- Run `--finish` in the foreground unless your harness re-invokes you when
  a background command completes (Claude Code's background tasks do) — if
  completion won't wake you, backgrounding it leaves the user waiting in
  silence.
- Re-running `--finish` with the same deviceCode is always safe: it returns
  immediately if the user already authorized and resumes polling otherwise.
  If your harness kills it with a tool timeout, just run it again.
- `{"status":"ok"}` means signed in — confirm with `zero auth whoami
  --json`. `{"status":"expired"}` means the code lapsed: start over from
  step 1, and this time make the `url` + `userCode` the final message of
  your turn, then run `--finish` when the user next replies.

#### No human in the loop

When your operator set you up to run autonomously (throwaway sandboxes, CI,
agent fleets) and isn't available to approve a sign-in, Zero supports
anonymous agent registration — an account and managed wallet created without
a browser, an email, or a human step (the auth.md protocol; see
<https://zero.xyz/auth.md>):

```bash
zero auth agent register
```

It prints the new wallet's address and persists the session in
`~/.zero/config.json`. The account starts unfunded: free capabilities work
immediately; paid ones need funding first — check prices before spending,
and stay inside whatever budget your operator authorized.

A human can take ownership of the account later:

```bash
zero auth agent claim <their-email>
```

prints a URL for them to open; they read a pairing code back to you and the
account, wallet, and history become theirs. When an operator is available
now, the device sign-in above is the better path — no claim step needed.

### Step 4 — try it out (optional)

Once authentication succeeds, the install works. A nice first thing to try:
ask Zero to build and host a simple site, e.g.

> "Build me a simple, but visually stunning hello world site and host it with
> Zero for free."

Offer it if it fits — skip it if the user already has their own task in mind.

---

## If something fails

Support can be requested with the command below; after sending it, stop —
the remaining steps won't succeed without a working install. Substitute the
placeholder values: your agent/harness name plus a brief note on what failed
(the field caps at 300 characters). The `email` field is how Zero replies
when support for your harness lands — it's your operator's email and their
choice: ask if they want to leave one, and omit the field entirely if not.

```bash
curl -sS -X POST https://api.zero.xyz/v1/request-agent-access \
  -H "Content-Type: application/json" \
  -d '{"agent":"<the agent or harness you are, with version>","email":"<optional email for a reply>"}'
```

Humans (or browser-driving agents — the page exposes a WebMCP tool) can use
the form at <https://zero.xyz/request-agent-access> instead.
