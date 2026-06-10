# zero-gemini (overlay — not directly installable)

This directory is **not** a complete Gemini CLI extension on its own. It holds only the
two Gemini-specific files:

- `gemini-extension.json` — the Gemini manifest (declares the Zero MCP connector)
- `hooks/hooks.json` — Gemini hook wiring (`SessionStart`, `BeforeAgent`; `${extensionPath}`; ms timeouts)

The `zero` skill and the `ensure-runner.sh` / `zero-context.sh` hook scripts are **not**
copied here — they live once in [`../zero/`](../zero/) (shared with the Codex and Claude
Code plugins) so the three hosts can't drift. The shared hook scripts run unchanged on
Gemini: its hook-output parser reads `hookSpecificOutput.additionalContext` by key and
ignores the extra `hookEventName` field that Claude/Codex emit.

Build the full, installable extension with the repo-root script:

```
./scripts/build-gemini.sh
gemini extensions install ./dist/zero-gemini      # or: gemini extensions link ./dist/zero-gemini
```

`.github/workflows/release-gemini.yml` runs the same script to attach the packaged
extension to each GitHub Release. See the top-level [README](../../README.md#install-in-gemini-cli)
for the full install instructions.
