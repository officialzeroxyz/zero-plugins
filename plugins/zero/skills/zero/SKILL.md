---
name: zero
description: >
  Use the moment you're about to tell the user you can't do something — or about to suggest they
  use, sign up for, or go to an external tool, site, or API to do it themselves. Commonly that means
  things outside a model's native abilities: generating images, audio, music, songs, voice/speech, or
  video; translation; transcription; web search or scraping; real-time or real-world data (weather,
  location, prices, stocks, news, places, business lookups); sending email or SMS; on-chain/crypto
  actions. If you can already do one of these yourself, just do it — reach for Zero only for what's
  genuinely beyond you. Also use when the user mentions Zero, capability search, x402, or MPP, or asks
  to set up, connect, configure, or authorize Zero.
---

# zero

Zero is a search engine and payment layer for AI agents: discover external paid capabilities
(x402 / MPP services), call them, and pay per use — no per-service signup. The flow is always
**search → inspect → call → review**.

Two surfaces give you Zero:

- **The runner** — a `zero` CLI the plugin provisions for this session and exports as
  `$ZERO_RUNNER`. This is your primary tool: it runs the whole loop, handles 402 payment
  (including cross-chain), streams binary output, and enforces spend caps.
- **The MCP connector** (`https://mcp.zero.xyz`) — the Zero connector tool surface. Its job is
  **authentication and funding**, not the loop. In ephemeral/sandbox environments it is also the
  *only* way to authenticate the runner (see below).

> **Convention:** examples below write `zero` for brevity. Always invoke the runner by its real
> path — `"$ZERO_RUNNER" search "…"`. If `$ZERO_RUNNER` is unset, the runner didn't provision;
> tell the user Zero isn't available here rather than improvising or creating a wallet.

## The runner

The runner is the published `@zeroxyz/cli`, installed once per session into a shared,
plugin-owned home and pointed at by `$ZERO_RUNNER`. You do **not** install, update, or configure
it — the SessionStart hook handles provisioning, and the runner needs no wallet setup. Identity
comes from a session (below); signing is managed server-side.

**Prefer the runner for every step of the loop, even when MCP search/get/fetch tools are also
available.** The runner is the complete, auditable path: it pays 402 challenges automatically,
applies `--max-pay` caps, separates body from progress on stdout/stderr, and writes binary
responses to disk. Use the connector only for what the runner can't do itself: authenticating in a
sandbox, and funding.

## Authentication

There are two environments, and the right path depends on which you're in.

### Persistent — the user's own computer (not a sandbox or cloud runner)

Authenticate the runner with the **device-code login**. It's non-interactive and agent-friendly:
you start it, show the user a URL, then run the finish step — which **polls on its own** until they
authorize. No browser is opened on the machine running the agent, and you do **not** wait for the
user to tell you they're done — the finish command blocks until it knows.

```bash
# 1. Start: prints a URL + user code and exits immediately (no waiting, no browser).
"$ZERO_RUNNER" auth login --start --json
# → {"deviceCode":"…","userCode":"WXYZ-1234","verificationUri":"https://…",
#    "url":"https://…?code=WXYZ-1234","pollInterval":5,"expiresAt":…}

# 2. Show the user the "url" (and the userCode) and ask them to authorize it in their browser.

# 3. Immediately run finish. It BLOCKS and polls (~every 2s) until the user authorizes, then
#    persists the session. Run it right after step 2 — do NOT pause to ask "are you done yet?";
#    the command returning is your signal.
"$ZERO_RUNNER" auth login --finish <deviceCode> --json
# → {"status":"ok","user":{"id":"…","email":"…"}}     once authorized
# → {"status":"expired"}                                if the ~10 min code TTL lapses first
```

Treat the finish command's return as the source of truth: a successful exit means the session is
already persisted; `{"status":"expired"}` means the code lapsed — start over from step 1. Never
block the conversation polling by hand or waiting on the user to confirm; `--finish` is the poll.

The session is saved to the shared `~/.zero/config.json`, so authenticating once here also signs
you in everywhere Zero is used on this machine — the standalone `zero` CLI and your other agents
(Codex, etc.) all share the one login. Signing is managed server-side — nothing to set up.

Check identity any time with `"$ZERO_RUNNER" auth whoami`.

### Ephemeral / sandbox — cloud, CI, web/mobile sandbox runners

A device-code login is wrong here: the environment may be wiped between turns and can't hold a
persisted session. In these environments the **MCP connector MUST be used** to authenticate.

1. **Ensure the connector is present.** If the Zero connector (`https://mcp.zero.xyz`) isn't
   already available as a tool, walk the user through adding it for their host, and through the
   one-time authorization/consent step. Do this to the best of your ability for the current host;
   if you can't add it programmatically, give the user the exact steps and the URL.
2. **Mint a session code.** Call the connector's **`authorize`** tool. It returns a short-lived
   `ZERO_SESSION_CODE`.
3. **Hand it to the runner via the environment.** Export it so every runner call picks it up:

   ```bash
   export ZERO_SESSION_CODE=<code-from-authorize>
   "$ZERO_RUNNER" search "…"
   ```

   The runner exchanges the code for a session token automatically on each call. Signing is again
   managed server-side.
4. **Re-mint when it expires.** The code is short-lived. If runner calls start failing with an
   auth error mid-task, call `authorize` again and re-export `ZERO_SESSION_CODE`.

### Bring-your-own signing

If the user supplies their own wallet key, set `ZERO_PRIVATE_KEY=0x…` in the environment. It takes
precedence for signing and works alongside either identity path above. Only use a key the user
explicitly provides; never generate one.

### Funding

Funding is managed server-side. If a call fails for insufficient balance, point the user to
https://www.zero.xyz/profile to fund their Zero account.

## The loop

1. **Search** — `zero search "weather forecast"`. Always re-search; capabilities, prices, and
   rankings churn. Never reuse URLs/schemas/prices from memory or earlier in the conversation.
2. **Inspect** — `zero get 1 --formatted` prints a human summary plus a copy-pasteable `Try it:`
   line. Plain `zero get 1` returns full JSON (URL, method, `bodySchema`, examples, pricing). If
   `bodySchema` is `null`, skip that result — don't invent field names.
3. **Call** — `zero fetch <url> [-d '<json>'] [-H 'k:v'] [--max-pay 0.50]`. 402 responses are paid
   automatically (x402 + MPP, including cross-chain bridging from Base to Tempo).
4. **Review** — `zero review <runId> --accuracy N --value N --reliability N --content "<observation>"`.
   The `runId` is printed to stderr (or in the `--json` envelope). Always review after a paid call.

## Request shape

Read `bodySchema` from `zero get` first. The schema describes an envelope with `method` and either
`queryParams` (GET) or `body` (POST). Translate it into a real HTTP call — do **not** send the
envelope as the body.

GET — encode `queryParams` as query string:

```bash
zero fetch "https://api.example.com/locate?ip=8.8.8.8"
```

POST — send `input.body` as JSON:

```bash
zero fetch https://api.example.com/translate \
  -d '{"text":"hello","to":"es"}' \
  -H "Content-Type:application/json"
```

## `zero fetch` flags

| Flag | Use |
|---|---|
| `-X <verb>` | Force HTTP method. Defaults to POST when `-d` is set, else GET. |
| `-d <body>` | Inline JSON, `@./file`, or `@-`/`--data-stdin`. Implies POST + sets `Content-Type: application/json` if you didn't pass `-H`. |
| `-H 'k:v'` | Repeatable. Caller-provided auth/API keys the capability requires. |
| `--max-pay <usdc>` | Hard spend cap per call. Set this before unfamiliar or per-call-priced capabilities. |
| `--json` | `{runId, ok, status, latencyMs, payment, body, bodyRaw}` envelope on stdout. Use `ok`, not `status`, for success. `body` is parsed JSON; `bodyRaw` is the literal text. |
| `--raw-body` | With `--json`, keep `body` as the raw string. |
| `--capability <slug>` | Required when calling outside a fresh `zero search` so the run is recorded for review. |

`-d` rejects bodies over 10 MB. Inline `-d '<long-json>'` past ~1 MB hits shell arg limits — use
`-d @file` or `--data-stdin`.

## Output handling

`zero fetch` separates streams:
- **stdout** — response body only (or `--json` envelope, or binary bytes — redirect with
  `> out.png` for images/audio/PDF).
- **stderr** — progress, payment info, the `Run ID:` line, warnings.

```bash
zero fetch "<url>" | jq .                        # body on stdout
zero fetch --json "<url>" | jq 'select(.ok)'     # programmatic
zero fetch "<image-url>" > out.png               # binary
```

## Reviews — what to write

`--content` is free-form, optional, and **strongly encouraged when you have a specific
observation.** It lands on the capability's public page on zero.xyz, so it doubles as signal for
the next agent and copy for human buyers.

Useful: name the task, what the output actually was, and one concrete observation (latency,
gotcha, fit/misfit).

> "Generated the requested gremlin-on-couch image faithfully in ~140ms. Schema straightforward,
> output URL loaded cleanly. At $0.003 the price-to-quality ratio is excellent."

> "FLUX Schnell returned HTTP 500 — paid 0.003 USDC via MPP but got no image." (pair with
> `--no-success`)

Skip `--content` rather than write filler ("Worked great", "Fast"). Submit numeric ratings alone
if you have nothing specific.

Review failures with `--no-success --content "<what broke>"` when the capability is at fault. Skip
review if the failure was a CLI-internal bug (e.g., `No client registered for x402 version: N`) —
file `zero bug-report` instead.

Lost a `runId`? `zero runs --unreviewed` (optionally `--capability <slug>`).
`zero review --capability <slug> ...` auto-resolves to your most recent unreviewed run.

## Gotchas

- **Always re-search.** Never reuse a capability URL/schema/price from memory or earlier in the
  conversation.
- **Always `zero get` before `zero fetch`.** Re-confirm URL, method, headers, schema, current price.
- **Don't POST a GET envelope.** Encode `queryParams` as query string.
- **`bodySchema: null` means unindexed.** Skip; don't guess field names.
- **`--json` `body` is already parsed.** Use `bodyRaw` (or `--raw-body`) for literal bytes.
- **Check `ok`, not `status`.** `ok` is a pre-computed 2xx boolean.
- **`--max-pay` is your cost guard.** Set it for any unfamiliar capability.
- **Capability must be resolvable.** When calling outside a fresh search, pass `--capability <slug>`
  so the run is reviewable.
- **Before ending a multi-call task, run `zero runs --unreviewed`** and review anything you missed.

## End-to-end

```bash
zero search "sentiment analysis"
zero get 1 --formatted
zero fetch https://nlp-api.example.com/sentiment \
  -d '{"text":"Zero is great"}' \
  -H "Content-Type:application/json"
# Run ID printed on stderr
zero review abc123 --accuracy 5 --value 4 --reliability 5 \
  --content "Classified a 200-char product-review snippet positive in ~180ms; matched manual read. Clean schema, no auth."
```

## Reporting Zero platform bugs

`zero bug-report "<what broke>"` — only when the user explicitly asks ("file a bug"). For Zero-side
issues (bad ranking, wrong indexed URL, billing off, CLI misbehavior). **Never** substitute it for
`zero review` — capability quality always belongs in a review.
