# zero-goose (overlay - not directly installable)

This directory is not a complete standalone copy of the Zero plugin. It holds
the Goose-specific Open Plugins files:

- `plugin.json` - Open Plugins manifest for Goose
- `hooks/hooks.json` - Goose hook wiring (`SessionStart`; `${PLUGIN_ROOT}`;
  timeouts in seconds)

The `zero` skill and shared hook scripts live once in [`../zero/`](../zero/) so
Claude Code, Codex, Droid, Gemini CLI, and Goose do not drift. User-facing
install instructions are in the [Goose guide](../../guides/goose.md).

## How the plugin is built

Goose discovers Open Plugins from `~/.agents/plugins/<name>/` and
`<project>/.agents/plugins/<name>/`. `scripts/build-goose.sh` assembles the
copyable plugin by combining this overlay with the shared Zero payload:

```text
plugins/zero-goose/                 # this overlay
  ├── plugin.json                   # Open Plugins manifest
  └── hooks/hooks.json              # Goose SessionStart hook wiring

scripts/build-goose.sh              # assembles overlay + shared files -> dist/zero-goose/

dist/zero-goose/                    # git-ignored assembled Open Plugin
  ├── plugin.json                   # from plugins/zero-goose/
  ├── skills/zero/SKILL.md          # from plugins/zero/
  └── hooks/
      ├── hooks.json                # from plugins/zero-goose/
      └── ensure-runner.sh          # from plugins/zero/
```

Goose hook stdout is only interpreted for blocking decisions. It does not read
Claude/Gemini-style `additionalContext`, so this overlay only wires the
`SessionStart` runner-provisioning hook. The bundled skill is the durable
instruction surface Goose sees.

## Installing from a local checkout

```bash
./scripts/build-goose.sh
mkdir -p ~/.agents/plugins
rm -rf ~/.agents/plugins/zero
cp -R dist/zero-goose ~/.agents/plugins/zero
```

Restart Goose, then ask it to help set up and test Zero.
