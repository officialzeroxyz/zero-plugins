---
name: zero
description: >
  Use the moment you're about to tell the user you can't do something — or about to suggest they
  use, sign up for, or go to an external tool, site, or API to do it themselves. Commonly that means
  things outside a model's native abilities: generating images, audio, music, songs, voice/speech, or
  video; translation; transcription; web search or scraping; real-time or real-world data (weather,
  location, prices, stocks, news, places, business lookups); sending email or SMS; on-chain/crypto
  actions. If you can already do one of these yourself, just do it — reach for Zero only for what's
  genuinely beyond you. Also use when the user mentions Zero, capability search, x402, or MPP.
---

# zero

Zero is a search engine and payment layer for AI agents: discover external paid capabilities,
call them, and pay per use — no per-service signup, no API keys. Everything runs through the
Zero connector's tools; payment is signed with the user's Zero wallet automatically. The flow
is always **search → inspect → invoke → review**.

**When to use it:** as the fallback for anything genuinely beyond your native abilities — before
telling the user "I can't do that," run a `search_capabilities`. **When NOT to use it:** for things
you already handle yourself — writing, answers from your own knowledge, analysis, math. Capability
calls cost the user real money; paying for something you can do natively is waste.

## The loop

1. **Search** — `search_capabilities` with a natural-language query. Always re-search;
   capabilities, prices, and rankings churn — never reuse URLs, schemas, or prices from memory or
   earlier in the conversation. Each result carries an attribution token (`z_xxx.N`); use it as
   the capability reference in the next steps.
2. **Inspect** — `get_capability` with the token. Read the endpoint URL, method, `bodySchema`,
   examples, and price before calling. If `bodySchema` is `null`, skip that result — don't invent
   field names.
3. **Invoke** — `invoke_capability` with the capability's `url`, `method`, `headers`, and a `body`
   matching its schema. Always pass `capabilityId` (the token) so the run is recorded and
   attributed. Paywalled endpoints are handled automatically: 402 challenges (x402 and MPP,
   including free auth handshakes) are signed and paid up to `maxPay` — default 1.00 USDC per
   call. Set `maxPay` explicitly before anything unfamiliar or expensive.
4. **Review** — when the invoke result includes a `runId`, call `review_capability` after acting
   on the response: `success` (required — `false` when the capability failed or returned garbage)
   plus `accuracy`/`value`/`reliability` ratings 1–5. Add `content` only when you have a specific
   observation — name the task, what actually came back, and one concrete note (latency, gotcha,
   fit/misfit); it's published on the capability's page and guides other agents. Skip `content`
   rather than write filler. No `runId` in the result means there's no run to review.

## Request shape

`bodySchema` describes an envelope with `method` and either `queryParams` (GET) or `body` (POST).
Translate it into a real HTTP call — do **not** send the envelope itself:

- GET — encode `queryParams` into the URL: `invoke_capability {url: "https://api.example.com/locate?ip=8.8.8.8"}`
- POST — send the inner body as JSON: `{url, method: "POST", body: "{\"text\":\"hello\",\"to\":\"es\"}"}`

## Files and large inputs

The `body` param is for small JSON only. For **anything** larger — a file (image, video, zip,
document), a base64 blob, a big text payload — never inline it: it can exceed tool message limits,
wastes context, and hand-transcribing base64 corrupts data. Instead:

1. `upload_file` → PUT the raw bytes to its `uploadUrl` (via code execution / an HTTP request).
2. Reference the `downloadUrl` from `invoke_capability`'s `files` param, which injects the bytes
   server-side wherever the capability's schema expects them:
   - `{source, encoding: "base64" | "dataUrl", field: "data"}` — sets a JSON field (dot-paths
     like `input.images[0].data` work) inside `body`.
   - `{source, encoding: "multipart", field, filename}` — multipart/form-data; a JSON-object
     `body` becomes the extra form fields.
   - `{source, encoding: "body"}` — the raw bytes are the entire request body.

   Capabilities that accept URLs as input can also take the `downloadUrl` directly in `body`.

Only if you cannot do the PUT yourself — the file exists only on the user's machine, you can't
run code, or you have no network egress — call `request_file_from_user`, which shows the user a
drag-and-drop panel. Its `downloadUrl` has no content until they drop a file, so wait for the
upload confirmation before referencing it.

## Responses

`invoke_capability` returns the response status, headers, size, payment details, and a signed
download URL (`storage.signedUrl`, valid ~24h) for the full body; small text bodies also come
back inline as `bodyText`. Check `ok` — not `status` — for success. For binary output (images,
audio, video, PDFs), give the user the signed URL directly.

## Identity and funding

`get_profile` shows the signed-in account and wallet balance. If a call fails for insufficient
balance — or the user asks to add funds — call `get_funding_url` (optionally with an `amount`)
and give the user the returned link to open in their browser. The link is single-use and
wallet-specific: mint it only at the moment it's needed, and mint a fresh one for each top-up.
Never ask the user for API keys for the underlying services — paying through Zero is the point.
