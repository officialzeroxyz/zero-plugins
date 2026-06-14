#!/usr/bin/env bash
#
# Assemble the Goose Open Plugin into dist/zero-goose/.
#
# Goose discovers Open Plugins at ~/.agents/plugins/<name>/ and
# <project>/.agents/plugins/<name>/. The shared Zero skill and runner hook live
# once in plugins/zero/. This script overlays the Goose manifest and hook wiring
# on top of that shared payload so host-specific packaging cannot drift.
#
# Usage:
#   scripts/build-goose.sh                 # assemble dist/zero-goose/
#   scripts/build-goose.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-goose"
OUT="$ROOT/dist/zero-goose"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/plugin.json" \
  "$OVERLAY/hooks/hooks.json" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-goose: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/hooks"

cp "$OVERLAY/plugin.json" "$OUT/plugin.json"
cp "$OVERLAY/hooks/hooks.json" "$OUT/hooks/hooks.json"

cp "$SHARED/hooks/ensure-runner.sh" "$OUT/hooks/ensure-runner.sh"
cp -R "$SHARED/skills" "$OUT/skills"
chmod +x "$OUT/hooks/ensure-runner.sh"

echo "build-goose: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-goose: wrote $TARBALL"
fi
