#!/usr/bin/env bash
#
# Assemble the Zed adapter into dist/zero-zed/.
#
# Usage:
#   scripts/build-zed.sh                 # assemble dist/zero-zed/
#   scripts/build-zed.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-zed"
OUT="$ROOT/dist/zero-zed"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/zed/settings.json" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-zed: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/.agents/skills/zero" "$OUT/.zed"

cp "$OVERLAY/manifest.json"       "$OUT/manifest.json"
cp "$OVERLAY/zed/settings.json"   "$OUT/.zed/settings.json"
cp "$SHARED/skills/zero/SKILL.md" "$OUT/.agents/skills/zero/SKILL.md"

echo "build-zed: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-zed: wrote $TARBALL"
fi
