#!/usr/bin/env bash
#
# Assemble the Gemini CLI extension into dist/zero-gemini/.
#
# Single source of truth, no drift: the skill and the reusable hook scripts live ONCE in
# plugins/zero/ (shared with the Codex and Claude Code plugins). Gemini can't consume that
# directory directly — it needs gemini-extension.json at the extension root and auto-reads
# hooks/hooks.json, whose event names differ from Claude's — so this script overlays the
# two Gemini-specific files from plugins/zero-gemini/ on top of the shared content:
#
#   dist/zero-gemini/
#     ├── gemini-extension.json        # from plugins/zero-gemini/  (Gemini manifest)
#     ├── skills/                      # from plugins/zero/          (the shared 'zero' skill)
#     └── hooks/
#         ├── hooks.json               # from plugins/zero-gemini/  (Gemini events; ${extensionPath}; ms)
#         ├── ensure-runner.sh         # from plugins/zero/          (shared; Gemini tolerates the output JSON)
#         └── zero-context.sh          # from plugins/zero/          (shared; emitted on BeforeAgent)
#
# The shared ensure-runner.sh / zero-context.sh work unchanged on Gemini: its hook-output
# parser is lenient (it reads hookSpecificOutput.additionalContext by key and ignores the
# extra hookEventName field that Claude/Codex emit).
#
# Both the release workflow and local/dev installs run THIS script, so the packaged
# extension can never drift from what Codex and Claude ship.
#
# Usage:
#   scripts/build-gemini.sh                 # assemble dist/zero-gemini/
#   scripts/build-gemini.sh --tar OUT.tgz   # also write a tarball (manifest at archive root)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$ROOT/plugins/zero"
OVERLAY="$ROOT/plugins/zero-gemini"
OUT="$ROOT/dist/zero-gemini"

TARBALL=""
if [ "${1:-}" = "--tar" ]; then
  TARBALL="${2:?--tar requires an output path}"
fi

# Sanity-check the inputs exist before we clobber dist/.
for f in \
  "$OVERLAY/gemini-extension.json" \
  "$OVERLAY/hooks/hooks.json" \
  "$SHARED/hooks/ensure-runner.sh" \
  "$SHARED/hooks/zero-context.sh" \
  "$SHARED/skills/zero/SKILL.md"; do
  [ -f "$f" ] || { echo "build-gemini: missing required input: $f" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/hooks"

# Gemini-specific overlay (manifest + hook declarations).
cp "$OVERLAY/gemini-extension.json" "$OUT/gemini-extension.json"
cp "$OVERLAY/hooks/hooks.json"       "$OUT/hooks/hooks.json"

# Shared, host-agnostic content (the single source of truth).
cp "$SHARED/hooks/ensure-runner.sh"  "$OUT/hooks/ensure-runner.sh"
cp "$SHARED/hooks/zero-context.sh"   "$OUT/hooks/zero-context.sh"
cp -R "$SHARED/skills"               "$OUT/skills"
chmod +x "$OUT/hooks/ensure-runner.sh" "$OUT/hooks/zero-context.sh"

echo "build-gemini: assembled $OUT"
find "$OUT" -type f | sed "s#^$ROOT/##" | sort

if [ -n "$TARBALL" ]; then
  # Archive the CONTENTS of dist/zero-gemini so gemini-extension.json is at the tarball
  # root (Gemini's installer expects the manifest at the archive root).
  mkdir -p "$(dirname "$TARBALL")"
  tar -czf "$TARBALL" -C "$OUT" .
  echo "build-gemini: wrote $TARBALL"
fi
