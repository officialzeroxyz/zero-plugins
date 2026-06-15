#!/usr/bin/env bash
#
# Assemble the Trae adapter into dist/zero-trae/.
#
# Usage:
#   scripts/build-trae.sh                 # assemble dist/zero-trae/
#   scripts/build-trae.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-trae"
OUT="$ROOT/dist/zero-trae"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/trae/mcp.json" \
  "$OVERLAY/trae/mcp-install-link.txt" \
  "$OVERLAY/trae/rules/zero.md" \
  "$OVERLAY/trae/commands/zero.md" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-trae: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.trae/skills/zero" \
  "$OUT/.trae/rules" \
  "$OUT/.trae/commands" \
  "$OUT/.agents/skills/zero" \
  "$OUT/trae"

cp "$OVERLAY/manifest.json"              "$OUT/manifest.json"
cp "$OVERLAY/trae/mcp.json"              "$OUT/.trae/mcp.json"
cp "$OVERLAY/trae/mcp-install-link.txt"  "$OUT/trae/mcp-install-link.txt"
cp "$OVERLAY/trae/rules/zero.md"         "$OUT/.trae/rules/zero.md"
cp "$OVERLAY/trae/commands/zero.md"      "$OUT/.trae/commands/zero.md"
cp "$SHARED/skills/zero/SKILL.md"        "$OUT/.trae/skills/zero/SKILL.md"
cp "$SHARED/skills/zero/SKILL.md"        "$OUT/.agents/skills/zero/SKILL.md"

echo "build-trae: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-trae: wrote $TARBALL"
fi
