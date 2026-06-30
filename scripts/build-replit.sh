#!/usr/bin/env bash
#
# Assemble the Replit Agent adapter into dist/zero-replit/.
#
# Replit Agent has no local plugin bundle or project-level MCP config, so this
# script builds a small project template: the shared Zero skill in
# .agents/skills plus a Replit MCP install-link payload for UI/listing work.
#
# Usage:
#   scripts/build-replit.sh                 # assemble dist/zero-replit/
#   scripts/build-replit.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-replit"
OUT="$ROOT/dist/zero-replit"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/replit/mcp-install.json" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-replit: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.agents/skills" \
  "$OUT/replit"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/replit/mcp-install.json" "$OUT/replit/mcp-install.json"
cp -R "$SHARED/skills/zero" "$OUT/.agents/skills/zero"

echo "build-replit: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-replit: wrote $TARBALL"
fi
