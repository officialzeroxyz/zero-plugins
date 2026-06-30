#!/usr/bin/env bash
#
# Assemble the Devin Desktop / Windsurf adapter into dist/zero-devin/.
#
# Devin Desktop has no one-artifact plugin installer, so this script builds a
# project template. The Devin-specific overlay lives in plugins/zero-devin/; the
# shared Zero skill and runner hooks live once in plugins/zero/.
#
# Usage:
#   scripts/build-devin.sh                 # assemble dist/zero-devin/
#   scripts/build-devin.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-devin"
OUT="$ROOT/dist/zero-devin"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/devin/config.json" \
  "$OVERLAY/devin/hooks.v1.json" \
  "$OVERLAY/devin/hooks/auto-approve-zero.sh" \
  "$OVERLAY/devin/rules/zero.md" \
  "$OVERLAY/windsurf/mcp_config.json" \
  "$OVERLAY/windsurf/workflows/zero.md" \
  "$SHARED/skills/zero/SKILL.md" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/hooks/zero-context.sh"; do
  [ -f "$f" ] || { echo "build-devin: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.agents/skills" \
  "$OUT/.devin/rules" \
  "$OUT/.devin/skills" \
  "$OUT/.devin/zero/hooks" \
  "$OUT/.windsurf/workflows"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/devin/config.json" "$OUT/.devin/config.json"
cp "$OVERLAY/devin/hooks.v1.json" "$OUT/.devin/hooks.v1.json"
cp "$OVERLAY/devin/rules/zero.md" "$OUT/.devin/rules/zero.md"
cp "$OVERLAY/windsurf/mcp_config.json" "$OUT/.windsurf/mcp_config.json"
cp "$OVERLAY/windsurf/workflows/zero.md" "$OUT/.windsurf/workflows/zero.md"
cp -R "$SHARED/skills/zero" "$OUT/.agents/skills/zero"
cp -R "$SHARED/skills/zero" "$OUT/.devin/skills/zero"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/.devin/zero/hooks/ensure-runner.sh"
cp "$SHARED/hooks/zero-context.sh" "$OUT/.devin/zero/hooks/zero-context.sh"
cp "$OVERLAY/devin/hooks/auto-approve-zero.sh" "$OUT/.devin/zero/hooks/auto-approve-zero.sh"
chmod +x "$OUT/.devin/zero/hooks/"*.sh

echo "build-devin: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-devin: wrote $TARBALL"
fi
