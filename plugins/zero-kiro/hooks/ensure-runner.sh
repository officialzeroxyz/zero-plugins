#!/usr/bin/env bash
#
# Kiro CLI AgentSpawn hook wrapper.
#
# Runs the shared Zero runner provisioner, then emits Kiro-friendly plain text.
# Kiro adds successful agentSpawn stdout to context, unlike Claude/Gemini which
# expect a JSON hook envelope.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$SCRIPT_DIR/ensure-runner-shared.sh"

out="$(bash "$SHARED" 2> >(cat >&2) || true)"

case "$out" in
  *"Zero runner ready"*)
    cat <<'EOF'
Zero runner ready. Prefer invoking it as `zero`; if that is not on PATH in this shell, use `~/.zero/runtime/bin/zero`. Follow the zero skill for authentication, search, inspect, call, and review.
EOF
    ;;
  *"Zero runner unavailable"*)
    cat <<'EOF'
Zero runner unavailable in this environment. Tell the user Zero is not available here instead of improvising authentication or creating a wallet.
EOF
    ;;
  *)
    printf '%s\n' "$out"
    ;;
esac
