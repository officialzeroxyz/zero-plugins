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
(x402 / MPP services), call them, and pay per use — no per-service signup. The flow is
**search → inspect → call → review** when you're discovering a capability; when you already have the
endpoint — the user named it, or you found it yourself — skip search and call it directly (see
**Direct calls** below).

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

Every example below invokes the runner as plain `zero`, and that is also what you should type
in real commands whenever it resolves: users read your commands, and `zero search …` reads like
a normal CLI where `"$ZERO_RUNNER" search …` reads like machinery. The name is generic, though,
so resolve it once, before your first call — don't trust `$PATH` blindly. Take the first tier
that resolves to a working executable, then use the same spelling everywhere `zero` appears
below:

1. **`zero` on `$PATH`** — preferred. Either the provisioned runner (the SessionStart hook
   prepends its directory to PATH: immediately on hosts that persist hook env vars, in new
   shells elsewhere) or a standalone CLI install (`npm install -g @zeroxyz/cli`). Trust it
   without further checks when `command -v zero` matches `$ZERO_RUNNER` or points into
   `$HOME/.zero/runtime/bin`; any other path counts only if `zero --help` prints the Zero CLI
   header (`Zero CLI — Search engine for AI agents`). Anything else → fall through.
2. **`$ZERO_RUNNER`** — the runner's absolute path, exported by the SessionStart hook on hosts
   that persist hook env vars (Claude Code, Codex). The fallback spelling when bare `zero`
   doesn't resolve yet or failed the check above.
3. **`$HOME/.zero/runtime/bin/zero`** — the provisioned runner's well-known path, for hosts
   that don't persist hook env vars (e.g. Gemini CLI); the SessionStart hook reports it.
4. **`npx -y @zeroxyz/cli@latest`** — ephemeral/sandbox environments only, where nothing is
   provisioned or installed (see **Ephemeral / sandbox** below).

```bash
ZERO="$(command -v zero || true)"                     # tier 1 — verify per the rules above
[ -n "$ZERO" ] || ZERO="${ZERO_RUNNER:-}"
[ -x "$ZERO" ] || ZERO="$HOME/.zero/runtime/bin/zero"
```

When tier 1 wins, invoke it as plain `zero`; on the lower tiers use the absolute path (which
also survives shells that don't persist variables between commands).

If no tier resolves in a persistent environment, tell the user Zero isn't available here —
don't install the CLI yourself. In an ephemeral sandbox, fall through to `npx`. Never generate
a private-key wallet yourself either way (managed wallets come from auth — see below).

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

Before touching any auth command, decide **who the account is for**:

- **A human is present** (or asked you to sign *them* in) → `zero auth login`. It's the device
  flow below and creates their account on first sign-in; `zero auth register` is an alias for
  the same command, not a separate signup.
- **Fully autonomous — no human in the loop** → `zero auth agent register`. Anonymous account
  plus a managed wallet, no browser, no one to hand a URL to.
- **Never** use `zero auth agent register` when a human is present — it mints an account owned
  by *no one* (a human can only take it over later via the claim flow). If there's a human,
  `zero auth login` already creates their account.

Beyond that, the environment picks the mechanics.

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
all share the one login.

Check identity any time with `zero auth whoami`.

### Autonomous — no human in the loop (`zero auth agent register`)

When there is genuinely no human to send to a browser, register an anonymous agent account:

```bash
zero auth agent register --json
# → {"status":"ok","registrationId":"…","userId":"…","walletAddress":"0x…",
#    "claimTokenExpires":"…"}
```

One command, no browser, no waiting. What you get:

- A signed-in session, persisted to `~/.zero/config.json` like any other login.
- A **managed wallet, created at signup** — you can search, get, fetch, and pay immediately.
  It starts empty: fund it with `zero wallet fund` (`--no-open` prints the funding URL instead
  of opening a browser; the link is one-time use).
- A **claim token**, saved in `~/.zero/config.json` — a human's future path to owning this
  account. It expires (the deadline is printed at registration and stored as
  `claimTokenExpires` in the config), and an unclaimed account is cleaned up after the
  registration expires — so hand the account to a human (below) before then if the work
  should outlive it.

If it errors with "Already signed in", there's an existing session — don't stack a fresh
anonymous account on top of it.

### Claim handoff — `zero auth agent claim <email>`

When a human should own an agent-registered account, link it to them. The ceremony is the
**reverse of the device flow**: the hosted claim page shows the *human* a pairing code, they
read it back to you, and *you* complete with the code.

```bash
# 1. Start: prints the hosted claim URL.
zero auth agent claim human@example.com

# 2. Send the human the URL. They sign in as that email and the page shows THEM a pairing code.

# 3. They read the code back to you. On a TTY the command prompts for it inline; in
#    non-interactive runs, complete with a second invocation:
zero auth agent claim human@example.com --code <code>
```

`--code` completes the attempt already in flight — re-running *without* `--code` mints a fresh
link and invalidates the code the human is holding. After the claim, the account belongs to the
human, every pre-claim session is revoked, and the CLI rotates onto fresh credentials
automatically — nothing to re-run. If the start step fails, the claim token has likely expired
(check `claimTokenExpires` in `~/.zero/config.json`).

### Ephemeral / sandbox — cloud, CI, web/mobile sandbox runners

A device-code login won't work — the environment can't hold a persisted session. Run the published
`@zeroxyz/cli` directly and authenticate via the **MCP connector's `authorize` tool**.

**Code execution is required.** This whole path runs the CLI in a shell; if the environment can't
execute commands, stop and have the user enable it.

**Egress (reactive, not a gate).** `zero fetch` calls each capability's own URL on arbitrary
domains, so the environment needs unrestricted outbound access — not just the npm registry and
`*.zero.xyz`. A Zero-only allowlist passes search/get and then breaks every fetch. Don't verify
this up front. If a fetch hangs or fails with a DNS/connection error, restricted egress is the
first thing to suspect: have the user select "All domains" (or the equivalent unrestricted-egress
option). Reaching `*.zero.xyz` alone doesn't prove arbitrary-domain egress.

1. **Get the runner — install once, don't `npx` per call.** Per-call
   `npx -y @zeroxyz/cli@latest` re-resolves the package every time (~2–3s each, even warm) and
   prints npm notices to stderr. If the sandbox filesystem persists across commands — most do,
   even when each command runs in a fresh *shell* — install once and call the bare binary:

   ```bash
   npm install -g @zeroxyz/cli@latest    # ~1s cached; puts `zero` on PATH
   zero --help                            # ~0.9s/call thereafter
   ```

   Only if the filesystem is reset between commands (no install survives) fall back to
   `npx -y @zeroxyz/cli@latest` everywhere `zero` appears below.
2. **Authorize.** If the connector (`https://mcp.zero.xyz`) isn't available as a tool yet, walk the
   user through adding it and the one-time consent. Then call its **`authorize`** tool to get a
   short-lived authorization `code`.
3. **Exchange the code for a session token — without printing it.** The code from `authorize` is
   one-time; the reusable credential is the session token that `zero auth exchange` returns. The
   command writes the bare token to stdout precisely so you can capture it straight to disk. Never
   run it bare, `echo`/`cat` the token, or paste it into the conversation — the token must not land
   in the transcript. The token file lives on disk, so — like the install above — it survives a
   fresh shell; the axis that matters is filesystem persistence, not env persistence.

   ```bash
   # Typical harness: fresh shell per command (env vars don't carry over), persistent filesystem.
   # Write the token to an owner-only file once, then load it per call:
   (umask 077; zero auth exchange <code from authorize> > /tmp/zero-session-token)
   ZERO_SESSION_TOKEN="$(cat /tmp/zero-session-token)" zero search "…"
   ```

   Every CLI call picks `ZERO_SESSION_TOKEN` up from the environment. (`auth exchange --json` emits
   `{token, expiresAt}` instead, if you need the expiry.)
4. **Re-mint when it expires.** The token is short-lived and has no refresh path. If calls start
   failing with an auth error mid-task, call `authorize` again, re-run `auth exchange`, and
   re-capture `ZERO_SESSION_TOKEN` the same way.
5. **Reviewing across a fresh shell.** The `runId` on `fetch`'s stderr is gone by the next command
   in a fresh-shell harness — so capture it from the `--json` envelope at call time (see **Output
   handling**) and review by runId rather than re-deriving the slug (see **Reviews — what to
   write**).

### Bring-your-own signing

If the user supplies their own wallet key, set `ZERO_PRIVATE_KEY=0x…` in the environment. It takes
precedence for signing and works alongside either identity path above. Only use a key the user
explicitly provides; never generate one.

### Funding

Funding is managed server-side. If a call fails for insufficient balance, point the user to
https://www.zero.xyz/profile to fund their Zero account. On an agent-registered account there
is no signed-in human profile — use `zero wallet fund --no-open` and relay the one-time funding
URL instead.

## Direct calls

Zero works on any endpoint, not just indexed ones. Whenever you already have a specific URL to call
— the user named it, or you discovered it yourself (e.g. a storefront or API you found while
browsing) — call it directly: `zero fetch <url>`. Being absent from Zero's index is no reason to
refuse it or to swap in a different, indexed capability instead. Search is for when you need to
*find* a capability; don't insist on it when you already know what to call.

A `--capability` value (token, slug, or uid) comes from `zero search` or a capability's page, so you
won't have one for a URL you reached this way — omit it and just pass the URL. The server matches the
URL to a capability on its own for attribution when it recognizes it; if it doesn't, the call still
runs, it just isn't recorded as a reviewable run.

## The loop

1. **Search** — `zero search "weather forecast"`. Always re-search; capabilities, prices,
   and rankings churn. Never reuse URLs/schemas/prices from memory or earlier in the conversation.
   Each result includes a short **attribution token** (`token` field, format `z_xxx.N` where `N` is
   the 1-based position). Use this token — not the position number — in subsequent steps; it encodes
   the search context so the run is tied back to the originating search for attribution.
2. **Inspect** — `zero get <token> --formatted` (e.g. `zero get z_Ab12cd.1`) prints a human
   summary plus a copy-pasteable `Try it:` line. Plain `zero get <token>` returns full JSON
   (URL, method, `bodySchema`, examples, pricing). You can also pass a slug or uid. If `bodySchema`
   is `null`, skip that result — don't invent field names.
3. **Call** — `zero fetch <url> --capability <token> [-d '<json>'] [-H 'k:v'] [--max-pay 0.50]`.
   Pass `--capability <token>` so the run is recorded and attributed to the search. 402 responses
   are paid automatically (x402 + MPP, including cross-chain bridging from Base to Tempo).
4. **Review** — `zero review <runId> --success --accuracy N --value N --reliability N --content "<observation>"`.
   `--success` (or `--no-success` when the capability failed) is **required** — the command errors
   without one. The `runId` is printed to stderr (or in the `--json` envelope). Always review after
   a paid call.

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
| `--timeout <seconds>` | Per-request timeout (default 60), applied to each HTTP leg — probe and paid retry — not as a wall-clock deadline. Raise it up front for slow capabilities (image/video/audio often need `--timeout 300`) so the call doesn't die at 60s after payment. |
| `--json` | `{runId, ok, status, latencyMs, payment, body, bodyRaw}` envelope on stdout. Use `ok`, not `status`, for success. `body` is parsed JSON; `bodyRaw` is the literal text. |
| `--raw-body` | With `--json`, keep `body` as the raw string. |
| `--capability <id>` | Attribution token (`z_xxx.N` from search), slug, or uid — records the run and attributes it to the search. Pass it whenever you have one: the token from search results, or a slug/uid you already hold. You won't have any of these for a URL you reached without searching (see **Direct calls**) — omit it and the server attributes the URL itself when it can. |

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

Capture the `runId` from the `--json` envelope (`{runId, ok, …}`) rather than scraping it from
stderr — it's the handle `zero review` needs, and a prior call's stderr may be gone by the time you
review (especially in a fresh-shell harness).

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

Every review needs an outcome flag or the command errors: `--success` when the call delivered,
`--no-success --content "<what broke>"` when the capability failed. Skip review only if the failure
was a CLI-internal bug (e.g. `No client registered for x402 version: N`) — file `zero bug-report`
instead.

Review by `runId` (from the `fetch --json` envelope). `zero review --capability <slug>` can
auto-resolve to your most recent unreviewed run, but only with the *exact* recorded slug — which is
host-prefixed and hash-suffixed (e.g. `image-withzero-xyz-…-f422560b`), not guessable. Lost the
runId? `zero runs --unreviewed` lists every pending run with its slug.

## Gotchas

Quick pre-flight, each detailed above: re-search every time; `zero get` before every `zero fetch`;
encode GET `queryParams` as a query string (don't POST the envelope); skip `bodySchema: null` rather
than guess fields; check `ok`, not `status`; set `--max-pay` on anything unfamiliar; raise
`--timeout` for slow image/video/audio so the call doesn't die after payment; every `zero review`
needs `--success`/`--no-success`; pass `--capability <token|slug|uid>` whenever you have one.

- **`--capability` drives review attribution** — after a search, pass the `z_xxx.N` token so the run
  ties back to it; that keeps the capability's reliability signal fresh and lets you review it. If
  you already hold a slug/uid but didn't search, pass that. For a URL you reached without either (see
  **Direct calls**) you have nothing to pass — omit it; the server attributes the URL when it can,
  and only a URL it can't resolve ends up as an unreviewable run.
- **Before ending a multi-call task, run `zero runs --unreviewed`** and review anything you missed.
- **Zero reminder injected twice per prompt?** A plugin install and a standalone install
  (`zero init`) are coexisting; the harness may also warn the user about a shadowed Zero
  skill or hook. Harmless — don't fix it by deleting files. If the user wants the duplicate
  gone, `zero uninstall` removes the standalone copy — machine-wide, for every app reading
  the shared `~/.claude`/`~/.agents` directories — so offer it, don't run it unprompted.

## End-to-end

```bash
zero search "sentiment analysis"
# Each result shows a token (z_xxx.N) — use it as the capability reference
zero get z_Ab12cd.1 --formatted
zero fetch https://nlp-api.example.com/sentiment \
  --capability z_Ab12cd.1 \
  -d '{"text":"Zero is great"}' \
  -H "Content-Type:application/json"
# Run ID printed on stderr (also in --json envelope as .runId)
zero review abc123 --success --accuracy 5 --value 4 --reliability 5 \
  --content "Classified a 200-char product-review snippet positive in ~180ms; matched manual read. Clean schema, no auth."
```

## Reporting Zero platform bugs

`zero bug-report "<what broke>"` — only when the user explicitly asks ("file a bug"). For Zero-side
issues (bad ranking, wrong indexed URL, billing off, CLI misbehavior). **Never** substitute it for
`zero review` — capability quality always belongs in a review.
