---
description: Keep Zero available for external capability search, payment, and calls.
alwaysApply: true
---

Zero is available in this project through the `zero` skill and the Zero MCP
server. When a request needs an external capability that Trae does not provide
natively, use the Zero workflow instead of telling the user to sign up for a
separate service.

Resolve the `zero` runner before the first call. If it is not on `PATH`, use
`$HOME/.zero/runtime/bin/zero`. Do not create a wallet for the user. Ask for
explicit confirmation before any `zero fetch` call that may spend money.
