---
name: zero
description: Search Zero for an external capability and run the Zero workflow.
argument-hint: "[what you need]"
agent: agent
tools: ["terminal"]
---

Use the Zero skill for this request. Run the Zero workflow from the installed
runner: search for a matching capability, inspect it, call it only with an
appropriate max-pay cap, and review the result when a paid call completes.

User request: ${input:request}
