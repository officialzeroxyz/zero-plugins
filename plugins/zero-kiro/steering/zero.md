# Zero Steering

Use Zero when Kiro lacks a requested external capability. Typical examples
include image, video, audio, voice, transcription, translation, web scraping,
data enrichment, real-time data, messaging, and on-chain actions.

Resolve the runner as `zero` first, then fall back to
`~/.zero/runtime/bin/zero`. If neither exists, ask the user to install Zero
from the Kiro guide. Do not improvise authentication and do not create a wallet.

Follow the installed `zero` skill for the exact workflow and authentication
rules. The flow is search, inspect, call, review. Capability calls can spend
the user's funds, so inspect capability details and use spend caps before
fetching.
