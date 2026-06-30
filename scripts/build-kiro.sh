#!/usr/bin/env bash
#
# Assemble the Kiro package into dist/zero-kiro/.
#
# Kiro has two relevant install surfaces:
#   - Kiro IDE Powers: POWER.md + optional mcp.json + steering/
#   - Kiro CLI / IDE skills: ~/.kiro/skills/<name>/SKILL.md
#
# Powers do not currently install skills into ~/.kiro/skills, so the build
# output keeps those surfaces separate and the guide tells users where each one
# goes.
#
# Usage:
#   scripts/build-kiro.sh                 # assemble dist/zero-kiro/
#   scripts/build-kiro.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-kiro"
OUT="$ROOT/dist/zero-kiro"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/POWER.md" \
  "$OVERLAY/mcp.json" \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/agents/zero.json" \
  "$OVERLAY/hooks/ensure-runner.sh" \
  "$OVERLAY/hooks/zero-context.sh" \
  "$OVERLAY/steering/zero.md" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-kiro: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/power" "$OUT/agents" "$OUT/hooks"

cp "$OVERLAY/POWER.md" "$OUT/power/POWER.md"
cp "$OVERLAY/mcp.json" "$OUT/power/mcp.json"
cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp -R "$OVERLAY/steering" "$OUT/power/steering"

cp "$OVERLAY/agents/zero.json" "$OUT/agents/zero.json"
cp "$OVERLAY/hooks/ensure-runner.sh" "$OUT/hooks/ensure-runner.sh"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/hooks/ensure-runner-shared.sh"
cp "$OVERLAY/hooks/zero-context.sh" "$OUT/hooks/zero-context.sh"
cp -R "$SHARED/skills" "$OUT/skills"
chmod +x "$OUT/hooks/ensure-runner.sh" "$OUT/hooks/ensure-runner-shared.sh" "$OUT/hooks/zero-context.sh"

echo "build-kiro: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-kiro: wrote $TARBALL"
fi
