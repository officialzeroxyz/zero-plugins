#!/usr/bin/env bash
#
# Assemble the Warp adapter into dist/zero-warp/.
#
# Warp does not currently have a one-artifact plugin installer or lifecycle
# hooks, so this script builds a project template. The Warp-specific overlay
# lives in plugins/zero-warp/; the shared Zero skill lives once in plugins/zero/.
#
# Usage:
#   scripts/build-warp.sh                 # assemble dist/zero-warp/
#   scripts/build-warp.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-warp"
OUT="$ROOT/dist/zero-warp"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/warp/.mcp.json" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-warp: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.agents/skills" \
  "$OUT/.warp/skills"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/warp/.mcp.json" "$OUT/.warp/.mcp.json"
cp -R "$SHARED/skills/zero" "$OUT/.warp/skills/zero"
cp -R "$SHARED/skills/zero" "$OUT/.agents/skills/zero"

echo "build-warp: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-warp: wrote $TARBALL"
fi
