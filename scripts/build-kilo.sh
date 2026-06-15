#!/usr/bin/env bash
#
# Assemble the Kilo Code adapter into dist/zero-kilo/.
#
# Usage:
#   scripts/build-kilo.sh                 # assemble dist/zero-kilo/
#   scripts/build-kilo.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-kilo"
OUT="$ROOT/dist/zero-kilo"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/kilo/kilo.jsonc" \
  "$OVERLAY/kilo/legacy-mcp.json" \
  "$OVERLAY/kilo/marketplace-mcp.json" \
  "$OVERLAY/kilo/remote-skills/index.json" \
  "$OVERLAY/kilo/rules/zero.md" \
  "$OVERLAY/kilo/commands/zero.md" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-kilo: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.kilo/skills/zero" \
  "$OUT/.kilo/rules" \
  "$OUT/.kilo/commands" \
  "$OUT/.kilocode" \
  "$OUT/.agents/skills/zero" \
  "$OUT/.claude/skills/zero" \
  "$OUT/kilo/remote-skills/zero" \
  "$OUT/kilo"

cp "$OVERLAY/manifest.json"                    "$OUT/manifest.json"
cp "$OVERLAY/kilo/kilo.jsonc"                  "$OUT/.kilo/kilo.jsonc"
cp "$OVERLAY/kilo/legacy-mcp.json"             "$OUT/.kilocode/mcp.json"
cp "$OVERLAY/kilo/marketplace-mcp.json"        "$OUT/kilo/marketplace-mcp.json"
cp "$OVERLAY/kilo/remote-skills/index.json"    "$OUT/kilo/remote-skills/index.json"
cp "$OVERLAY/kilo/rules/zero.md"               "$OUT/.kilo/rules/zero.md"
cp "$OVERLAY/kilo/commands/zero.md"            "$OUT/.kilo/commands/zero.md"
cp "$SHARED/skills/zero/SKILL.md"              "$OUT/.kilo/skills/zero/SKILL.md"
cp "$SHARED/skills/zero/SKILL.md"              "$OUT/.agents/skills/zero/SKILL.md"
cp "$SHARED/skills/zero/SKILL.md"              "$OUT/.claude/skills/zero/SKILL.md"
cp "$SHARED/skills/zero/SKILL.md"              "$OUT/kilo/remote-skills/zero/SKILL.md"

echo "build-kilo: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-kilo: wrote $TARBALL"
fi
