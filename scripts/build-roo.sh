#!/usr/bin/env bash
#
# Assemble the Roo Code adapter into dist/zero-roo/.
#
# Usage:
#   scripts/build-roo.sh                 # assemble dist/zero-roo/
#   scripts/build-roo.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-roo"
OUT="$ROOT/dist/zero-roo"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/roo/mcp.json" \
  "$OVERLAY/roo/marketplace-mcp.json" \
  "$OVERLAY/roo/rules/zero.md" \
  "$OVERLAY/roo/commands/zero.md" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-roo: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.roo/skills/zero" \
  "$OUT/.roo/rules" \
  "$OUT/.roo/commands" \
  "$OUT/.agents/skills/zero" \
  "$OUT/roo"

cp "$OVERLAY/manifest.json"             "$OUT/manifest.json"
cp "$OVERLAY/roo/mcp.json"              "$OUT/.roo/mcp.json"
cp "$OVERLAY/roo/marketplace-mcp.json"  "$OUT/roo/marketplace-mcp.json"
cp "$OVERLAY/roo/rules/zero.md"         "$OUT/.roo/rules/zero.md"
cp "$OVERLAY/roo/commands/zero.md"      "$OUT/.roo/commands/zero.md"
cp "$SHARED/skills/zero/SKILL.md"       "$OUT/.roo/skills/zero/SKILL.md"
cp "$SHARED/skills/zero/SKILL.md"       "$OUT/.agents/skills/zero/SKILL.md"

echo "build-roo: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-roo: wrote $TARBALL"
fi
