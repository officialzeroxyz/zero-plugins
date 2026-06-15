# Zero for Kilo Code

How to install Zero in Kilo Code and keep it up to date.

## Install

### Inside Kilo Code

Install the Zero runtime once:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
```

Build the Kilo adapter from this repository, then copy it into your project:

```bash
scripts/build-kilo.sh
cp -R dist/zero-kilo/. /path/to/your/project/
```

Open the project in Kilo Code, then:

1. Open Settings > Agent Behaviour > MCP Servers and confirm the `zero` server
   from `.kilo/kilo.jsonc`.
2. Confirm `.kilo/kilo.jsonc` includes `.kilo/rules/zero.md` in the
   `instructions` array.
3. Start a new session so Kilo re-scans project skills and rules.
4. Use `/zero` or ask Kilo: *"Help me set up and test Zero."*

If you want a remote skill install instead, host the contents of
`dist/zero-kilo/kilo/remote-skills/` and add that URL to `skills.urls` in
`kilo.jsonc`.

### From the terminal

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-kilo.sh
cp -R dist/zero-kilo/. /path/to/your/project/
```

Restart the Kilo session, then ask Kilo: *"Help me set up and test Zero."*

## Staying up to date

Kilo Code does not currently provide lifecycle hooks for this adapter. To
update Zero, re-run:

```bash
curl -fsSL https://zero.xyz/install.sh | bash
scripts/build-kilo.sh
cp -R dist/zero-kilo/. /path/to/your/project/
```
