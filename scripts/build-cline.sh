#!/usr/bin/env bash
#
# Assemble the Cline adapter into dist/zero-cline/.
#
# Cline's editor extensions do not currently consume Cline SDK plugins, so this
# script builds a project template. The Cline-specific overlay lives in
# plugins/zero-cline/; the shared Zero skill lives once in plugins/zero/.
#
# Usage:
#   scripts/build-cline.sh                 # assemble dist/zero-cline/
#   scripts/build-cline.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-cline"
OUT="$ROOT/dist/zero-cline"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/cline/zero/mcp.json" \
  "$OVERLAY/clinerules/workflows/zero.md" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-cline: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.cline/skills" \
  "$OUT/.cline/zero" \
  "$OUT/.clinerules/workflows"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/cline/zero/mcp.json" "$OUT/.cline/zero/mcp.json"
cp "$OVERLAY/clinerules/workflows/zero.md" "$OUT/.clinerules/workflows/zero.md"
cp -R "$SHARED/skills/zero" "$OUT/.cline/skills/zero"

echo "build-cline: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-cline: wrote $TARBALL"
fi
