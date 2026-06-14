# Zero for OpenCode

OpenCode plugin package for Zero.

This package prepares the Zero runner, installs the Zero skill into OpenCode's
skill directory, registers the Zero MCP server, writes a `/zero` command,
injects the Zero availability reminder, adds `ZERO_RUNNER` and
`~/.zero/runtime/bin` to shell tool environments, and auto-allows safe read-only
Zero commands. It does not auto-allow `zero fetch` or wallet/funding commands.

Consumer installation instructions live in
[`../../guides/opencode.md`](../../guides/opencode.md).
