#!/usr/bin/env bash
#
# Antigravity PreInvocation hook.
#
# Antigravity does not have a SessionStart hook. Run the shared Zero runner
# provisioner here, discard its Claude/Codex-shaped JSON, then emit the
# Antigravity PreInvocation shape with a short reminder.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DIR/ensure-runner.sh" >/dev/null || true

cat <<'JSON'
{"injectSteps":[{"ephemeralMessage":"Zero is available for external paid capabilities. Use the zero skill for the search -> inspect -> call flow. Resolve the runner as zero on PATH, $ZERO_RUNNER, or ~/.zero/runtime/bin/zero; the Antigravity Zero plugin provisions ~/.zero/runtime/bin/zero before model invocations."}]}
JSON
