#!/usr/bin/env bash
#
# Assemble the Amp package into dist/zero-amp/.
#
# Amp reads project plugins from .amp/plugins/*.ts and project skills from
# .agents/skills/<name>/SKILL.md. Skills can bundle MCP servers with mcp.json,
# so the Zero MCP connector is copied directly into the Zero skill folder.
#
# Usage:
#   scripts/build-amp.sh                 # assemble dist/zero-amp/
#   scripts/build-amp.sh --tar OUT.tgz   # also write a tarball

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-amp"
OUT="$ROOT/dist/zero-amp"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

for f in \
  "$OVERLAY/manifest.json" \
  "$OVERLAY/skill/mcp.json" \
  "$OVERLAY/plugins/zero.ts" \
  "$OVERLAY/hooks/zero-context.sh" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-amp: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/.agents/skills" "$OUT/.amp/plugins" "$OUT/.amp/zero/hooks"

cp "$OVERLAY/manifest.json" "$OUT/manifest.json"
cp "$OVERLAY/plugins/zero.ts" "$OUT/.amp/plugins/zero.ts"
cp "$OVERLAY/hooks/zero-context.sh" "$OUT/.amp/zero/hooks/zero-context.sh"
cp "$SHARED/hooks/ensure-runner.sh" "$OUT/.amp/zero/hooks/ensure-runner-shared.sh"
cp -R "$SHARED/skills/zero" "$OUT/.agents/skills/zero"
cp "$OVERLAY/skill/mcp.json" "$OUT/.agents/skills/zero/mcp.json"

cat > "$OUT/.amp/zero/hooks/ensure-runner.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$SCRIPT_DIR/ensure-runner-shared.sh"

# Use a workspace-local shim so Amp can invoke `.amp/zero/hooks/zero-runner`
# even before ~/.zero/runtime/bin is on PATH.
export ZERO_RUNNER_SHIM="${ZERO_RUNNER_SHIM:-$SCRIPT_DIR/zero-runner}"

bash "$SHARED"

if [ -x "$HOME/.zero/runtime/bin/zero" ]; then
  ln -sfn "$HOME/.zero/runtime/bin/zero" "$ZERO_RUNNER_SHIM"
fi
EOF

chmod +x \
  "$OUT/.amp/zero/hooks/ensure-runner.sh" \
  "$OUT/.amp/zero/hooks/ensure-runner-shared.sh" \
  "$OUT/.amp/zero/hooks/zero-context.sh"

echo "build-amp: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-amp: wrote $TARBALL"
fi
