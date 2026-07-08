# Zero for any agent (standalone installer)

How to install Zero in any agent or harness with a shell. Use this when there's
no dedicated guide for your agent.

## Install

If you have npm (Node.js 20+), run this in your terminal:

```bash
npm i -g @zeroxyz/cli && zero init
```

No npm? Use the standalone installer:

```bash
curl -fsSL https://www.zero.xyz/install.sh | bash
```

That's it — Zero sets itself up automatically and works across all your agents.
You only need to do this once per machine.

When it finishes, ask your agent: *"Help me set up and test Zero."* It walks you
through signing in (a quick browser sign-in, once per machine).

### Using an agent with its own skills folder?

The installer already covers nearly every agent. If yours keeps skills in its
own folder and didn't pick Zero up, point the installer at that folder:

```bash
zero init --skills-dir ~/.youragent/skills
```

## Staying up to date

To update, just re-run whichever install command you used:

```bash
npm i -g @zeroxyz/cli
# or
curl -fsSL https://www.zero.xyz/install.sh | bash
```

If Zero is already installed, it simply updates in place. Safe to run as often
as you like.

## Uninstalling

Changed your mind? Remove Zero completely:

```bash
zero uninstall
```

---

Setting Zero up for a coding agent and want the full technical details — what
gets installed where, authentication, and per-agent plugins? See
[agent-install.md](agent-install.md).
