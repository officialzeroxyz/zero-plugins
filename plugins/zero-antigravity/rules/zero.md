# Zero

Zero is available in this Antigravity environment for paid external capabilities.
Use it only when the requested outcome requires a capability outside the agent's
native tools, such as image/video/audio generation, scraping, real-time data,
messaging, or other external services.

Prefer the `zero` CLI runner for the whole flow:

1. `zero search "<task>"`
2. `zero get <result>`
3. `zero fetch <url> ... --max-pay <amount>`

If `zero` is not on PATH, resolve it from `$ZERO_RUNNER` or
`~/.zero/runtime/bin/zero`. The Zero plugin provisions that runtime before
Antigravity model invocations.
