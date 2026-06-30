#!/usr/bin/env bash
#
# Assemble the Cursor adapter into dist/zero-cursor/.
#
# Cursor does not currently have a one-artifact plugin installer for local
# skills, hooks, and MCP config, so this script builds a project template. The
# Cursor-specific overlay lives in plugins/zero-cursor/; shared Zero content
# lives once in plugins/zero/.
#
# Usage:
#   scripts/build-cursor.sh                 # assemble dist/zero-cursor/
#   scripts/build-cursor.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-cursor"
OUT="$ROOT/dist/zero-cursor"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/cursor/hooks.json" \
  "$OVERLAY/cursor/hooks/ensure-runner.sh" \
  "$OVERLAY/cursor/mcp.json" \
  "$OVERLAY/cursor/permissions.json" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-cursor: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.agents/skills" \
  "$OUT/.cursor/skills" \
  "$OUT/.cursor/zero/hooks"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/cursor/hooks.json" "$OUT/.cursor/hooks.json"
cp "$OVERLAY/cursor/mcp.json" "$OUT/.cursor/mcp.json"
cp "$OVERLAY/cursor/permissions.json" "$OUT/.cursor/permissions.json"

cp -R "$SHARED/skills/zero" "$OUT/.cursor/skills/zero"
cp -R "$SHARED/skills/zero" "$OUT/.agents/skills/zero"
cp "$OVERLAY/cursor/hooks/ensure-runner.sh" "$OUT/.cursor/zero/hooks/ensure-runner.sh"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/.cursor/zero/hooks/ensure-runner-shared.sh"
chmod +x "$OUT/.cursor/zero/hooks/ensure-runner.sh" "$OUT/.cursor/zero/hooks/ensure-runner-shared.sh"

echo "build-cursor: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-cursor: wrote $TARBALL"
fi
