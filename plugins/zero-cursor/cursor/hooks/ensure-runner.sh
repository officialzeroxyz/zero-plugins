#!/usr/bin/env bash
#
# Cursor sessionStart hook wrapper.
#
# Runs the shared Zero runner provisioner for its side effects, then emits a
# Cursor-shaped hook response. The shared script emits Claude/Codex-style
# hookSpecificOutput JSON, so Cursor should not receive it directly.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HOOK_DIR/ensure-runner-shared.sh" >/dev/null || true

cat <<'JSON'
{"continue":true,"agent_message":"Zero runner is provisioned at ~/.zero/runtime/bin/zero. Use the zero skill for external paid capabilities; read-only zero search/get/runs/review commands can be auto-run, while zero fetch and wallet actions should remain user-reviewed."}
JSON
