# Install Zero

Zero ([zero.xyz](https://www.zero.xyz)) is a search engine and payment layer for
AI agents: search for a capability, call it, and pay per use. The CLI is
published on npm as
[`@zeroxyz/cli`](https://www.npmjs.com/package/@zeroxyz/cli); the plugin
packaging and this runbook are maintained at
[officialzeroxyz/zero-plugins](https://github.com/officialzeroxyz/zero-plugins).

## Install

The default path is npm — it works in any harness with Node.js:

| Environment | Command |
|---|---|
| Anything with npm (default) | `npm i -g @zeroxyz/cli && zero init` |
| Claude Code | `claude plugin marketplace add officialzeroxyz/zero-plugins && claude plugin install zero@zero-plugins` |
| Codex | `codex plugin marketplace add officialzeroxyz/zero-plugins && codex plugin add zero@zero-plugins` |
| Gemini CLI | `gemini extensions install https://github.com/officialzeroxyz/zero-plugins` |
| Hermes Agent | `hermes plugins install officialzeroxyz/zero-plugins/plugins/zero-hermes/hermes --force --enable` |
| Claude Chat (claude.ai) / Claude Cowork | no shell — follow [zero.xyz/install/claude.md](https://www.zero.xyz/install/claude.md) instead |
| None of the above | see [Fallback installer](#fallback-installer) |

The npm row installs the CLI from the public
[`@zeroxyz/cli`](https://www.npmjs.com/package/@zeroxyz/cli) package (inspect
it with `npm view @zeroxyz/cli`), then `zero init` integrates the skill and
hooks with every harness it detects. The Claude Code, Codex, Gemini CLI, and
Hermes Agent rows are per-harness alternatives that install through that
harness's own plugin manager: they add the zero-plugins repo as a source (or,
for Hermes, install straight from a subdirectory of it), then install the
Zero plugin via the manager's normal review-and-consent flow. The plugin's
full contents are listed below. The npm and fallback rows end by running
`zero init`.

## What the plugin installs

The plugin-manager rows install the same contents, from
[`plugins/zero/`](https://github.com/officialzeroxyz/zero-plugins/tree/main/plugins/zero)
in the repo (Hermes Agent installs the same skill and session-start hook from
[`plugins/zero-hermes/hermes/`](https://github.com/officialzeroxyz/zero-plugins/tree/main/plugins/zero-hermes/hermes),
where they are vendored for its plugin format; instead of an auto-approve
hook — Hermes hooks can't approve — it adds a guard that blocks `zero fetch`
commands missing an explicit `--max-pay` cap, plus a `/zero` command):

- **A skill** — the usage guide for the `zero` CLI
  ([source](https://github.com/officialzeroxyz/zero-plugins/blob/main/plugins/zero/skills/zero/SKILL.md))
- **An MCP connector** pointing at `mcp.zero.xyz` — how clients without a
  shell (Claude web and mobile) sign in and reach Zero; CLI harnesses use
  the `zero` CLI instead
- **Three hooks**
  ([source](https://github.com/officialzeroxyz/zero-plugins/tree/main/plugins/zero/hooks)):
  - `SessionStart` — installs the `zero` CLI into `~/.zero/runtime/`
    (downloads Node only if the system lacks v20+) and puts it on PATH. On
    harnesses without session-env support this appends one PATH line to the
    shell rc (`ZERO_PATH_AUTOADD=0` skips it). Also refreshes the plugin
    install in the background at most once a day
    (`ZERO_PLUGIN_AUTOUPDATE=0` disables).
  - `UserPromptSubmit` — adds a one-line reminder that Zero is available
    for tasks beyond the agent's built-in abilities
  - `PreToolUse` — auto-approves read-only `zero` subcommands (`search`,
    `get`, `review`, …). `zero fetch` (spends money) and `zero wallet`
    are never auto-approved; those always go through the harness's normal
    permission prompt.

## What `zero init` does

Runs automatically at the end of the npm and fallback install paths (the
plugin-manager rows integrate through the harness's own installer instead).
It:

- writes the Zero skill into every well-known agent-skill directory it finds
  on the machine (currently includes `~/.claude/skills/` and
  `~/.agents/skills/`, and others as harnesses are added — see [supported
  paths](https://github.com/officialzeroxyz/zero-plugins) for the current
  list)
- registers hook scripts in the config file of any harness it detects with
  its own hook system (e.g. `~/.claude/settings.json`)

It prints each file it writes as it goes. `zero uninstall` reverses all of
it.

## Read the skill file now

Skills normally load at session start, so the session that just ran the
install can't see the skill it installed yet. Read it now instead of
waiting for a reload or a new session:

- **npm / fallback path:** `zero init`'s output names the file it wrote —
  read whichever matches your harness, e.g. `~/.claude/skills/zero/SKILL.md`
  or `~/.agents/skills/zero/SKILL.md`.
- **Plugin-manager path:** the skill ships inside the installed plugin at
  `skills/zero/SKILL.md` under the plugin's install root.

That file is the day-to-day usage guide — the same one the harness loads at
the start of future sessions. Reading it now just brings this session up to
parity with the next one.

## Authenticate

Already signed in? `zero auth whoami --json` shows a `user` object when a
sign-in exists — if so, skip to [Try it](#try-it).

Both paths below create a free account. Account creation cannot make
purchases.

**Interactive** (a person is present to approve a browser sign-in) —
device-code sign-in, the same pattern as `gh auth login`:

```bash
zero auth login --start --json      # prints a url + code
zero auth login --finish <code> --json   # waits for browser approval
```

Whoever is signing in opens the URL, enters the code, and approves in their
browser. `--finish` polls until the sign-in is approved (expected, not a
hang), and re-running it with the same code is safe.

**Unattended** (sandboxes, CI — no one available for a browser step):

```bash
zero auth agent register --json
```

Output includes `"balance": 0, "payment_method": null` — the account exists
but can't purchase anything until a person funds it. A person can take
ownership of the account later with `zero auth agent claim <email>`.

## Check balance / add funds

```bash
zero wallet balance --json
```

Funds can only be added by a person in a browser; no CLI command adds funds
directly. If the balance is 0 and a paid capability is needed, the account
owner runs:

```bash
zero wallet fund --start --json     # same device-code pattern as sign-in
```

and completes payment-method setup and the amount in the browser. This is
the same regardless of which auth path created the account.

## Try it

```bash
zero search "<capability you need>"
zero fetch <result-id>
```

A good first task if you don't have one in mind: build a small site and host
it with Zero.

## Fallback installer

Only needed with no npm and no supported plugin manager. Installs Node (only
if the system doesn't have v20+) and the CLI into `~/.zero/runtime/`, adds
`zero` to PATH for this shell, then runs `zero init` (see above). The
script is plain shell; source is in the
[zero-plugins repo](https://github.com/officialzeroxyz/zero-plugins).

```bash
curl -fsSL https://www.zero.xyz/install.sh -o /tmp/zero-install.sh
bash /tmp/zero-install.sh
```

Re-run to update. `zero uninstall` reverses everything either path wrote.
