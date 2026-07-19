#!/usr/bin/env bash
#
# Vendor the shared Zero files into the Hermes plugin directory.
#
# Hermes installs the plugin straight from this repo's subdirectory
# (`hermes plugins install officialzeroxyz/zero-plugins/plugins/zero-hermes/hermes`),
# and a subdirectory install ships ONLY what is checked in under that path —
# the installed plugin cannot reach sibling directories like plugins/zero/.
# So the shared hook script and skill are vendored (committed) into the plugin
# directory by this script, and CI (hermes-plugin-sync.yml) fails any PR where
# the vendored copies drift from their sources.
#
# Usage:
#   scripts/sync-hermes.sh           # rewrite the vendored files in place
#   scripts/sync-hermes.sh --check   # exit 1 if the vendored files are stale
#
# Sources:
#   plugins/zero/hooks/ensure-runner.sh -> plugins/zero-hermes/hermes/hooks/ensure-runner.sh   (verbatim)
#   plugins/zero/skills/zero/SKILL.md   -> plugins/zero-hermes/hermes/skills/zero/SKILL.md     (Hermes frontmatter, shared body)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
PLUGIN="$ROOT/plugins/zero-hermes/hermes"

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

for f in "$SHARED/hooks/ensure-runner.sh" "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "sync-hermes: missing source: $f" >&2; exit 1; }
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/hooks" "$STAGE/skills/zero"

cp "$SHARED/hooks/ensure-runner.sh" "$STAGE/hooks/ensure-runner.sh"

# Hermes skills use their own frontmatter shape; keep the shared skill body.
cat > "$STAGE/skills/zero/SKILL.md" <<'HEADER'
---
name: zero
description: Use Zero for capabilities beyond Hermes.
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
' "$SHARED/skills/zero/SKILL.md" >> "$STAGE/skills/zero/SKILL.md"

if [ "$CHECK" = "1" ]; then
  status=0
  for rel in hooks/ensure-runner.sh skills/zero/SKILL.md; do
    if ! diff -u "$PLUGIN/$rel" "$STAGE/$rel" >&2 2>/dev/null; then
      echo "sync-hermes: $rel is out of sync — run scripts/sync-hermes.sh" >&2
      status=1
    fi
  done
  exit "$status"
fi

mkdir -p "$PLUGIN/hooks" "$PLUGIN/skills/zero"
cp "$STAGE/hooks/ensure-runner.sh" "$PLUGIN/hooks/ensure-runner.sh"
cp "$STAGE/skills/zero/SKILL.md"   "$PLUGIN/skills/zero/SKILL.md"
chmod +x "$PLUGIN/hooks/ensure-runner.sh"
echo "sync-hermes: vendored files refreshed"
