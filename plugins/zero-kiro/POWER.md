---
name: "zero"
displayName: "Zero"
description: "Discover and call paid external capabilities from Kiro when native tools are not enough."
keywords: ["zero", "x402", "mpp", "capability search", "paid tools", "web scraping", "image generation", "video generation", "audio generation", "translation", "weather", "messaging", "crypto"]
author: "Zero"
---

# Zero

Zero is a search engine and payment layer for AI agents. Use it when a request
needs a capability Kiro does not have natively, such as image, video, or audio
generation, transcription, web scraping, data enrichment, real-time data,
messaging, or on-chain actions.

## Onboarding

1. Confirm the Zero skill is installed at `~/.kiro/skills/zero/SKILL.md` or
   `<workspace>/.kiro/skills/zero/SKILL.md`.
2. If `zero` is not on `PATH`, ask the user to run the standalone Zero
   installer from the Kiro guide. Do not create a wallet yourself.
3. Follow the Zero skill for the full workflow: search, inspect, call, review.
4. Use the bundled `zero` MCP server for account and authorization tasks.

## Tool Use

- Prefer Kiro's native abilities for coding, local files, shell commands, and
  analysis it can already perform.
- Use Zero before telling the user to sign up for a service, get an API key, or
  use an external tool themselves.
- Capability calls may cost real money. Inspect the capability and cap spend
  before calling it.
- Always review paid runs using the instructions in the Zero skill.
