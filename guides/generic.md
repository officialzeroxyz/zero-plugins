# Zero for any agent (standalone installer)

How to install Zero in any agent or harness with a shell — and for humans at a
terminal — then keep it up to date.

Use this when there's no dedicated guide for your agent. Claude Code, Codex,
Droid, and Gemini CLI each have their own — prefer those if one matches. This
installer sets up the exact same Zero, so you end up in the same place.

## Install

Run this in your terminal:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
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

- Zero updates itself automatically each time you start a session.
- To refresh everything by hand, re-run `zero init` — it's safe to run as often
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
