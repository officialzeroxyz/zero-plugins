# zero-mcp

The Zero MCP connector plus the `zero` skill, and nothing else — no hooks, no
scripts, no CLI dependency. Everything runs through the remote MCP server at
`https://mcp.zero.xyz` (OAuth sign-in in the browser; search is free, paid
calls are capped per-call by the calling agent's `maxPay`).

Install:

```bash
claude plugin marketplace add officialzeroxyz/zero-plugins
claude plugin install zero-mcp@zero-plugins
```

This is the connector-only alternative to the `zero` plugin — install one or
the other, not both (both register the Zero MCP server and skill).
