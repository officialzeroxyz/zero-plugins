#!/usr/bin/env bash
#
# Assemble the Crush adapter into dist/zero-crush/.
#
# Usage:
#   scripts/build-crush.sh                 # assemble dist/zero-crush/
#   scripts/build-crush.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-crush"
OUT="$ROOT/dist/zero-crush"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/crush/crush.zero.json" \
  "$OVERLAY/crush/hooks/zero-pre-tool-use.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-crush: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p \
  "$OUT/.crush/skills/zero" \
  "$OUT/.crush/hooks" \
  "$OUT/.agents/skills/zero" \
  "$OUT/crush"

write_crush_skill() {
  local dest="$1"
  cat > "$dest" <<'HEADER'
---
name: zero
description: Use Zero for external capabilities.
user-invocable: true
---
HEADER
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { in_frontmatter = 0; next }
    !in_frontmatter { print }
  ' "$SHARED/skills/zero/SKILL.md" >> "$dest"
}

cp "$OVERLAY/manifest.json"                       "$OUT/manifest.json"
cp "$OVERLAY/crush/crush.zero.json"               "$OUT/crush/crush.zero.json"
cp "$OVERLAY/crush/hooks/zero-pre-tool-use.sh"    "$OUT/.crush/hooks/zero-pre-tool-use.sh"
write_crush_skill                                 "$OUT/.crush/skills/zero/SKILL.md"
write_crush_skill                                 "$OUT/.agents/skills/zero/SKILL.md"
chmod +x "$OUT/.crush/hooks/zero-pre-tool-use.sh"

echo "build-crush: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-crush: wrote $TARBALL"
fi
