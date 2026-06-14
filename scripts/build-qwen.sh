#!/usr/bin/env bash
#
# Assemble the Qwen Code extension into dist/zero-qwen/.
#
# Source of truth, no drift: the reusable Zero skill and hook scripts live once
# in plugins/zero/. Qwen needs qwen-extension.json at the extension root and
# supports extension-bundled skills, commands, MCP servers, and Claude-style
# hooks in that manifest, so this script overlays the Qwen-specific files on top
# of the shared content.
#
# Usage:
#   scripts/build-qwen.sh                 # assemble dist/zero-qwen/
#   scripts/build-qwen.sh --tar OUT.tgz   # also write a tarball (manifest at archive root)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-qwen"
OUT="$ROOT/dist/zero-qwen"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/qwen-extension.json" \
  "$OVERLAY/commands/zero.md" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/hooks/zero-context.sh" \
  "$SHARED/hooks/auto-approve-zero.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-qwen: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/hooks" "$OUT/commands"

cp "$OVERLAY/qwen-extension.json" "$OUT/qwen-extension.json"
cp "$OVERLAY/commands/zero.md" "$OUT/commands/zero.md"

cp "$SHARED/hooks/ensure-runner.sh"       "$OUT/hooks/ensure-runner.sh"
cp "$SHARED/hooks/zero-context.sh"        "$OUT/hooks/zero-context.sh"
cp "$SHARED/hooks/auto-approve-zero.sh"   "$OUT/hooks/auto-approve-zero.sh"
cp -R "$SHARED/skills"                    "$OUT/skills"
chmod +x "$OUT/hooks/ensure-runner.sh" "$OUT/hooks/zero-context.sh" "$OUT/hooks/auto-approve-zero.sh"

echo "build-qwen: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-qwen: wrote $TARBALL"
fi
