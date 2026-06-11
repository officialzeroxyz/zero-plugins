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

**When to use it:** as the fallback for anything genuinely beyond your native abilities — before
telling the user "I can't do that," run a `zero search`. **When NOT to use it:** for things you
already handle yourself — writing code, answers from your own knowledge, local files, shell
commands, math. Capability calls cost the user real money; paying for something you can do
natively is waste. If you can do it yourself, just do it.

Two surfaces give you Zero:

- **The runner** — the `zero` CLI, provisioned by the plugin/extension for this session or
  installed standalone by the user (see **Resolving `zero`**). This is your primary tool: it runs
  the whole loop, handles 402 payment (including cross-chain), streams binary output, and enforces
  spend caps.
- **The MCP connector** (`https://mcp.zero.xyz`) — the Zero connector tool surface. Its job is
  **authentication and funding**, not the loop. In ephemeral/sandbox environments it is also the
  *only* way to authenticate the runner (see below).

## Resolving `zero`

Every example below invokes the runner as `zero`. That is shorthand for a **resolved runner**,
not an instruction to trust `$PATH` blindly. Resolve it once, before your first call, then use
the same resolved command everywhere `zero` appears below — substituting its absolute path if
your shell doesn't persist variables between commands. Take the first of these that resolves to
a working executable:

1. **`$ZERO_RUNNER`** — exported by the SessionStart hook on hosts that persist hook env vars
   (Claude Code, Codex).
2. **`$HOME/.zero/runtime/bin/zero`** — the provisioned runner's well-known path, for hosts
   that don't persist hook env vars (e.g. Gemini CLI); the SessionStart hook reports it.
3. **`zero` on `$PATH`** — a standalone CLI install (`npm install -g @zeroxyz/cli`). The name
   is generic, so don't trust it on sight: it counts only if `zero --help` prints the Zero CLI
   header (`Zero CLI — Search engine for AI agents`). Anything else → skip this tier.
4. **`npx -y @zeroxyz/cli@latest`** — ephemeral/sandbox environments only, where nothing is
   provisioned or installed (see **Ephemeral / sandbox** below).

```bash
ZERO="${ZERO_RUNNER:-}"
[ -x "$ZERO" ] || ZERO="$HOME/.zero/runtime/bin/zero"
[ -x "$ZERO" ] || ZERO="$(command -v zero || true)"   # then verify: "$ZERO" --help
```

If no tier resolves in a persistent environment, tell the user Zero isn't available here —
don't install the CLI yourself. In an ephemeral sandbox, fall through to `npx`. Never create a
wallet either way.

## The runner

The runner is the published `@zeroxyz/cli`. Under the plugin/extension it's installed once per
session into a shared, plugin-owned home and reported by its absolute path (also exported as
`$ZERO_RUNNER` on hosts that persist hook env vars; default path `~/.zero/runtime/bin/zero`); a
standalone `npm install -g @zeroxyz/cli` serves the same role. Either way you do **not** install,
update, or configure it yourself, and the runner needs no wallet setup. Identity comes from a
session (below); signing is managed server-side.

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
zero auth login --start --json
# → {"deviceCode":"…","userCode":"WXYZ-1234","verificationUri":"https://…",
#    "url":"https://…?code=WXYZ-1234","pollInterval":5,"expiresAt":…}

# 2. Show the user the "url" (and the userCode) and ask them to authorize it in their browser.

# 3. Immediately run finish. It BLOCKS and polls (~every 2s) until the user authorizes, then
#    persists the session. Run it right after step 2 — do NOT pause to ask "are you done yet?";
#    the command returning is your signal.
zero auth login --finish <deviceCode> --json
# → {"status":"ok","user":{"id":"…","email":"…"}}     once authorized
# → {"status":"expired"}                                if the ~10 min code TTL lapses first
```

Treat the finish command's return as the source of truth: a successful exit means the session is
already persisted; `{"status":"expired"}` means the code lapsed — start over from step 1. Never
block the conversation polling by hand or waiting on the user to confirm; `--finish` is the poll.

The session is saved to the shared `~/.zero/config.json`, so authenticating once here also signs
you in everywhere Zero is used on this machine — the standalone `zero` CLI and your other agents
all share the one login. Signing is managed server-side — nothing to set up.

Check identity any time with `zero auth whoami`.

### Ephemeral / sandbox — cloud, CI, web/mobile sandbox runners

A device-code login won't work — the environment can't hold a persisted session. Run the published
`@zeroxyz/cli` directly and authenticate via the **MCP connector's `authorize` tool**.

**Two prerequisites — confirm both first.** If either is missing, stop and walk the user through
enabling it in your product/environment:

- **Code execution** — you must be able to run shell commands to invoke the CLI.
- **Network egress to all domains** — not just the npm registry and `*.zero.xyz`: `zero fetch`
  calls each capability's own URL directly, and capabilities live on arbitrary domains you can't
  predict or allowlist up front. If the environment scopes outbound access, have the user select
  "All domains" (or the equivalent unrestricted-egress option) — a Zero-only allowlist will pass
  search/get and then break every fetch. Verify with a neutral third-party domain, e.g.
  `curl -sI https://example.com`; reaching `*.zero.xyz` alone doesn't prove arbitrary-domain
  egress. If calls hang or fail with DNS/connection errors mid-task, this is the first thing to
  re-check.

Then:

1. **Get the runner.** Resolve it with the ladder in **Resolving `zero`** above. In most
   sandboxes nothing is provisioned or installed, so it bottoms out at
   `npx -y @zeroxyz/cli@latest` (node/npx is present in most sandboxes) — substitute that
   wherever the examples use `zero`.
2. **Authorize.** If the connector (`https://mcp.zero.xyz`) isn't available as a tool yet, walk the
   user through adding it and the one-time consent. Then call its **`authorize`** tool to get a
   short-lived authorization `code`.
3. **Exchange the code for a session token — without printing it.** The code from `authorize` is
   one-time; the reusable credential is the session token that `zero auth exchange` returns. The
   command writes the bare token to stdout precisely so you can capture it straight into an env
   var or file. Never run it bare, `echo`/`cat` the token, or paste it into the conversation —
   the token must not land in the transcript.

   ```bash
   # If your shell persists across commands, capture it directly into the environment:
   export ZERO_SESSION_TOKEN="$(npx -y @zeroxyz/cli@latest auth exchange <code from authorize>)"
   npx -y @zeroxyz/cli@latest search "…"

   # If each command runs in a fresh shell (most agent harnesses), write it to an
   # owner-only file once, then load it per call:
   (umask 077; npx -y @zeroxyz/cli@latest auth exchange <code from authorize> > /tmp/zero-session-token)
   ZERO_SESSION_TOKEN="$(cat /tmp/zero-session-token)" npx -y @zeroxyz/cli@latest search "…"
   ```

   Every CLI call picks `ZERO_SESSION_TOKEN` up from the environment; signing is managed
   server-side. (`auth exchange --json` emits `{token, expiresAt}` instead, if you need the
   expiry.)
4. **Re-mint when it expires.** The token is short-lived and has no refresh path. If calls start
   failing with an auth error mid-task, call `authorize` again, re-run `auth exchange`, and
   re-capture `ZERO_SESSION_TOKEN` the same way.

### Bring-your-own signing

If the user supplies their own wallet key, set `ZERO_PRIVATE_KEY=0x…` in the environment. It takes
precedence for signing and works alongside either identity path above. Only use a key the user
explicitly provides; never generate one.

### Funding

Funding is managed server-side. If a call fails for insufficient balance, point the user to
https://www.zero.xyz/profile to fund their Zero account.

## The loop

1. **Search** — `zero search "weather forecast"`. Always re-search; capabilities, prices,
   and rankings churn. Never reuse URLs/schemas/prices from memory or earlier in the conversation.
2. **Inspect** — `zero get 1 --formatted` prints a human summary plus a copy-pasteable
   `Try it:` line. Plain `zero get 1` returns full JSON (URL, method, `bodySchema`,
   examples, pricing). If `bodySchema` is `null`, skip that result — don't invent field names.
3. **Call** — `zero fetch <url> [-d '<json>'] [-H 'k:v'] [--max-pay 0.50]`. 402 responses
   are paid automatically (x402 + MPP, including cross-chain bridging from Base to Tempo).
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
zero fetch "<url>" | jq .                    # body on stdout
zero fetch --json "<url>" | jq 'select(.ok)' # programmatic
zero fetch "<image-url>" > out.png           # binary
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
