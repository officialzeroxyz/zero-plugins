#!/usr/bin/env bash
#
# Kiro CLI UserPromptSubmit / AgentSpawn hook helper.
#
# Kiro CLI adds stdout from successful agentSpawn and userPromptSubmit hooks to
# the agent context, so emit plain text rather than Claude/Gemini hook JSON.

set -euo pipefail

cat <<'EOF'
Zero is available when installed for Kiro: use the zero skill before saying a requested external capability is unavailable or telling the user to sign up for a third-party service. Resolve the runner as `zero` or `~/.zero/runtime/bin/zero`, then follow the zero skill for search, inspect, call, and review. Do not create a wallet yourself.
EOF
