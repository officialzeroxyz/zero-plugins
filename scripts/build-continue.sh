#!/usr/bin/env bash
#
# Assemble the Continue CLI adapter into dist/zero-continue/.
#
# Continue does not currently have a one-artifact plugin installer for skills
# and hooks, so this script builds a project template. The Continue-specific
# overlay lives in plugins/zero-continue/; shared Zero skill and hook scripts
# live once in plugins/zero/.
#
# Usage:
#   scripts/build-continue.sh                 # assemble dist/zero-continue/
#   scripts/build-continue.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-continue"
OUT="$ROOT/dist/zero-continue"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/continue/settings.json" \
  "$OVERLAY/continue/mcpServers/zero.yaml" \
  "$OVERLAY/continue/prompts/zero.md" \
  "$SHARED/hooks/auto-approve-zero.sh" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/hooks/zero-context.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-continue: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.claude/skills" \
  "$OUT/.continue/mcpServers" \
  "$OUT/.continue/prompts" \
  "$OUT/.continue/skills" \
  "$OUT/.continue/zero/hooks"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/continue/settings.json" "$OUT/.continue/settings.json"
cp "$OVERLAY/continue/mcpServers/zero.yaml" "$OUT/.continue/mcpServers/zero.yaml"
cp "$OVERLAY/continue/prompts/zero.md" "$OUT/.continue/prompts/zero.md"

cp -R "$SHARED/skills/zero" "$OUT/.continue/skills/zero"
cp -R "$SHARED/skills/zero" "$OUT/.claude/skills/zero"
cp "$SHARED/hooks/auto-approve-zero.sh" "$OUT/.continue/zero/hooks/auto-approve-zero.sh"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/.continue/zero/hooks/ensure-runner.sh"
cp "$SHARED/hooks/zero-context.sh" "$OUT/.continue/zero/hooks/zero-context.sh"
chmod +x "$OUT/.continue/zero/hooks/"*.sh

echo "build-continue: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-continue: wrote $TARBALL"
fi
