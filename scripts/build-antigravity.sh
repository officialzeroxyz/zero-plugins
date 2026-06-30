#!/usr/bin/env bash
#
# Assemble the Antigravity plugin into dist/zero-antigravity/.
#
# Antigravity consumes a plugin directory with plugin.json at the root. The
# source overlay in plugins/zero-antigravity/ contains only Antigravity-specific
# manifests, hook declarations, and hook adapters; shared Zero skill and runner
# scripts are copied from plugins/zero/ at build time.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-antigravity"
OUT="$ROOT/dist/zero-antigravity"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/plugin.json" \
  "$OVERLAY/mcp_config.json" \
  "$OVERLAY/hooks.json" \
  "$OVERLAY/hooks/ensure-runner-antigravity.sh" \
  "$OVERLAY/hooks/auto-approve-zero-antigravity.sh" \
  "$OVERLAY/rules/zero.md" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-antigravity: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/hooks"

cp "$OVERLAY/plugin.json" "$OUT/plugin.json"
cp "$OVERLAY/mcp_config.json" "$OUT/mcp_config.json"
cp "$OVERLAY/hooks.json" "$OUT/hooks.json"
cp "$OVERLAY/hooks/ensure-runner-antigravity.sh" "$OUT/hooks/ensure-runner-antigravity.sh"
cp "$OVERLAY/hooks/auto-approve-zero-antigravity.sh" "$OUT/hooks/auto-approve-zero-antigravity.sh"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/hooks/ensure-runner.sh"
cp -R "$OVERLAY/rules" "$OUT/rules"
cp -R "$SHARED/skills" "$OUT/skills"
chmod +x "$OUT/hooks/ensure-runner-antigravity.sh" "$OUT/hooks/auto-approve-zero-antigravity.sh" "$OUT/hooks/ensure-runner.sh"

echo "build-antigravity: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-antigravity: wrote $TARBALL"
fi
