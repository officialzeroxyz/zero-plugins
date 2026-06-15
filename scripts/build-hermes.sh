#!/usr/bin/env bash
#
# Assemble the Hermes Agent adapter into dist/zero-hermes/.
#
# Usage:
#   scripts/build-hermes.sh                 # assemble dist/zero-hermes/
#   scripts/build-hermes.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-hermes"
OUT="$ROOT/dist/zero-hermes"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/hermes/plugin.yaml" \
  "$OVERLAY/hermes/__init__.py" \
  "$OVERLAY/hermes/mcp-zero.yaml" \
  "$SHARED/skills/zero/SKILL.md" \
  "$SHARED/hooks/ensure-runner.sh"; do
  [ -f "$f" ] || { echo "build-hermes: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.hermes/plugins/zero/hooks" \
  "$OUT/.hermes/plugins/zero/skills/zero" \
  "$OUT/.hermes/skills/zero/zero" \
  "$OUT/hermes"

write_hermes_skill() {
  local dest="$1"
  cat > "$dest" <<'HEADER'
---
name: zero
description: Use Zero for capabilities beyond Hermes.
version: 1.0.0
author: Zero
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [zero, capability-search, mcp, x402]
    category: automation
---
HEADER
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    !in_frontmatter { print }
  ' "$SHARED/skills/zero/SKILL.md" >> "$dest"
}

cp "$OVERLAY/manifest.json"             "$OUT/manifest.json"
cp "$OVERLAY/hermes/plugin.yaml"        "$OUT/.hermes/plugins/zero/plugin.yaml"
cp "$OVERLAY/hermes/__init__.py"        "$OUT/.hermes/plugins/zero/__init__.py"
cp "$OVERLAY/hermes/mcp-zero.yaml"      "$OUT/hermes/mcp-zero.yaml"
cp "$SHARED/hooks/ensure-runner.sh"     "$OUT/.hermes/plugins/zero/hooks/ensure-runner.sh"
write_hermes_skill                      "$OUT/.hermes/plugins/zero/skills/zero/SKILL.md"
write_hermes_skill                      "$OUT/.hermes/skills/zero/zero/SKILL.md"
chmod +x "$OUT/.hermes/plugins/zero/hooks/ensure-runner.sh"

echo "build-hermes: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-hermes: wrote $TARBALL"
fi
