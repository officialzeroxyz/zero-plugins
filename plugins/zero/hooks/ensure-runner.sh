#!/usr/bin/env bash
#
# Zero plugin — SessionStart hook.
#
# Provisions a Zero "runner" so the agent can call paid capabilities directly in its
# own environment, exports its path as $ZERO_RUNNER for the session, puts the runner
# on PATH as plain `zero` (env file for this session where supported, shell rc for
# everything else — see that section below), and tells the agent — via the
# SessionStart `additionalContext` payload — how to authenticate. Also refreshes the
# machine's Zero plugin installs once a day, in the background, through each host's
# own plugin-manager commands (see that section below). Because it both installs the
# runner and wires up PATH, this script doubles as the canonical standalone installer
# for agents with no plugin support at all.
#
# Runner model: the runner IS the published @zeroxyz/cli npm package (a single
# bundled, zero-dependency file as of 0.0.44), run on Node. We install it once per
# session into a plugin-owned runtime home and point a one-line shim at the installed
# entry, so $ZERO_RUNNER stays a single path and per-call overhead is just Node startup
# (~200ms) — not an npx resolve (~1s). The same code runs on Windows, macOS, Linux,
# and cloud sandboxes; only how we obtain Node varies:
#   a. system `node` (>= min major) on PATH if present — nothing is downloaded; else
#   b. download an official Node build (which bundles npm) into the runtime home, once.
#
# One Zero home (~/.zero), two deliberately namespaced areas:
#   - Runtime ($HOME/.zero/runtime): the downloaded Node, the npm cache, the installed
#     CLI, and the shim. Plugin-owned and disposable — safe to delete and rebuild. Kept
#     in its own subdir (not loose in ~/.zero) and contained via explicit --prefix /
#     npm_config_cache paths (NOT via $HOME). Shared across host plugins.
#   - Auth/config (~/.zero/config.json): the SAME file the standalone CLI and
#     skill.md-only agents use. The shim does NOT override $HOME, so one `auth login`
#     is shared across every Zero install method on the machine (plugin, skill.md, raw
#     CLI), not just plugin agents. Writes are additive (a session merges in alongside
#     any existing config), so existing CLI users are not disrupted: their privateKey
#     keeps signing until they opt into managed signing via `zero wallet migrate`.
#
# Auth: the agent never creates a wallet. For ephemeral/sandbox environments it mints a
# one-time code via the Zero MCP connector's authorize tool and exchanges it
# (`zero auth exchange`) for a short-lived ZERO_SESSION_TOKEN; for
# persistent environments a device-code `auth login` (persisted to ~/.zero) is
# preferred. An explicit ZERO_PRIVATE_KEY is honored for bring-your-own signing.
#
# Contract (hook mode): the ONLY thing written to stdout is a single SessionStart JSON
# object. All human/log output goes to stderr. Always exits 0 — a failed provisioning
# step degrades to a clear "unavailable" message rather than blocking the session.
#
# Install mode (--install): the standalone install path for humans and for agents with
# no plugin support — `curl -fsSL <raw url> | bash -s -- --install`. Same provisioning,
# but: a human summary replaces the JSON object, failures exit non-zero so scripts/CI
# can tell, the host-plugin refresh sweep is skipped (no plugin host to refresh), and
# the Zero skill is copied to the portable ~/.agents/skills/ directory so skills-capable
# agents pick it up. NOT ~/.claude/skills/: a standalone skill there would shadow the
# plugin's copy if the user later installs the plugin (the pre-1.0 leftover problem).

set -euo pipefail

# --- mode ---
INSTALL_MODE=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL_MODE=1 ;;
  esac
done

# --- Config (override via env) ---
# Plugin-owned RUNTIME area (Node, npm cache, installed CLI, shim), namespaced under the
# user's ~/.zero so there's a single Zero home. This is NOT the auth/config file: the shim
# leaves $HOME alone, so the login in ~/.zero/config.json is shared with the standalone CLI
# and skill.md-only agents. Override the location with ZERO_PLUGINS_HOME.
ZH="${ZERO_PLUGINS_HOME:-$HOME/.zero/runtime}"

# The published runner package and which version line to track. Default "latest";
# pin by exporting ZERO_CLI_SPEC=0.0.44 (a concrete version skips the registry check).
CLI_PKG="@zeroxyz/cli"
CLI_SPEC="${ZERO_CLI_SPEC:-latest}"

# Where official Node builds are fetched from, and which release line. node24 is the
# line the CLI is built/tested against.
NODE_DIST_BASE="${ZERO_NODE_DIST_BASE:-https://nodejs.org/dist}"
NODE_CHANNEL="${ZERO_NODE_CHANNEL:-latest-v24.x}"
# A system node older than this is treated as unusable -> we download instead.
NODE_MIN_MAJOR="${ZERO_NODE_MIN_MAJOR:-20}"
NODE_DIR="$ZH/node"            # downloaded Node lives here (if needed)
CLI_DIR="$ZH/cli"              # the installed @zeroxyz/cli
NPM_CACHE="$ZH/.npm"           # contained npm/npx cache
BIN_DIR="$ZH/bin"              # the shim
SHIM_PATH="$BIN_DIR/zero"
CLI_ENTRY="$CLI_DIR/node_modules/$CLI_PKG/dist/index.js"
INSTALLED_VERSION_FILE="$CLI_DIR/.installed-version"
RESOLVED_VERSION_FILE="$ZH/.cli-version"

log() { printf '[zero] %s\n' "$*" >&2; }

# Emit the SessionStart result. $1 is the status-specific message; JSON-escaped.
emit() {
  local ctx="$1"
  ctx="${ctx//\\/\\\\}"      # backslashes
  ctx="${ctx//\"/\\\"}"      # double quotes
  ctx="${ctx//$'\n'/ }"      # newlines -> spaces (JSON strings can't hold raw newlines)
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
}

# Report a fatal provisioning problem and stop. Hook mode emits the JSON "unavailable"
# context and exits 0 (never block a session); install mode prints the error and exits
# 1 so scripts and CI see the failure. $1 = agent-facing context, $2 = human one-liner.
fail() {
  if [ "$INSTALL_MODE" = "1" ]; then
    printf 'zero install failed: %s\n' "$2" >&2
    exit 1
  fi
  emit "$1"
  exit 0
}

# Append `export NAME=value` to the session env file so it persists for the session
# (Claude Code only — no-op elsewhere, e.g. Codex has no env-persistence file).
persist_env() {
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    printf 'export %s=%q\n' "$1" "$2" >> "$CLAUDE_ENV_FILE"
  fi
}

# --- platform detect ---
OS_KIND=""; ARCH=""
case "$(uname -s)" in
  Darwin)               OS_KIND="macos" ;;
  Linux)                OS_KIND="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS_KIND="win" ;;
esac
case "$(uname -m)" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64|amd64)  ARCH="x64" ;;
esac

node_major() {
  "$1" -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null || true
}

# Resolve a usable Node runtime, echoing its path on success. Prefers a recent-enough
# system node (downloads nothing); otherwise downloads an official build (which bundles
# npm) into $NODE_DIR once. The official macOS/Linux tarball and the Windows .zip both
# include npm/npx — we need npm to install the CLI, so we never use the bare node.exe.
resolve_node() {
  local sys major
  sys="$(command -v node 2>/dev/null || true)"
  if [ -n "$sys" ]; then
    major="$(node_major "$sys")"
    if [ -n "$major" ] && [ "$major" -ge "$NODE_MIN_MAJOR" ] 2>/dev/null; then
      log "using system node ($sys, v$major)"
      printf '%s' "$sys"; return 0
    fi
    log "system node too old (v${major:-?} < $NODE_MIN_MAJOR); will download"
  fi

  mkdir -p "$NODE_DIR"
  local node_os="$OS_KIND"; [ "$OS_KIND" = "macos" ] && node_os="darwin"

  if [ "$OS_KIND" = "win" ]; then
    # Windows: the official .zip bundles node.exe + npm + npx (the bare node.exe does
    # NOT include npm, which we need). Extract with unzip if available.
    local current="$NODE_DIR/current/node.exe"
    if [ -x "$current" ] && "$current" --version >/dev/null 2>&1; then
      log "using downloaded node ($current)"; printf '%s' "$current"; return 0
    fi
    command -v unzip >/dev/null 2>&1 || { log "no unzip available to extract the Node zip on Windows"; return 1; }
    local shasums artifact dir
    shasums="$(curl -fsSL "$NODE_DIST_BASE/$NODE_CHANNEL/SHASUMS256.txt" 2>/dev/null || true)"
    artifact="$(printf '%s\n' "$shasums" | grep -oE "node-v[0-9]+\.[0-9]+\.[0-9]+-win-${ARCH}\.zip" | head -1 || true)"
    [ -n "$artifact" ] || { log "could not resolve a node $NODE_CHANNEL win-${ARCH} build"; return 1; }
    dir="${artifact%.zip}"
    if curl -fsSL "$NODE_DIST_BASE/$NODE_CHANNEL/$artifact" -o "$NODE_DIR/$artifact" 2>/dev/null \
       && unzip -oq "$NODE_DIR/$artifact" -d "$NODE_DIR" 2>/dev/null; then
      ln -sfn "$NODE_DIR/$dir" "$NODE_DIR/current"
      rm -f "$NODE_DIR/$artifact" 2>/dev/null || true
      [ -x "$current" ] && "$current" --version >/dev/null 2>&1 && { log "installed node ($dir)"; printf '%s' "$current"; return 0; }
    fi
    rm -f "$NODE_DIR/$artifact" 2>/dev/null || true
    log "node download/extract failed for win-${ARCH}"
    return 1
  fi

  # macOS / Linux: official builds ship as tarballs (which include npm). Reuse an
  # extracted copy if it still runs; otherwise resolve the current version from
  # SHASUMS, download the .tar.gz (tar -z is universal), extract, symlink `current`.
  local current="$NODE_DIR/current/bin/node"
  if [ -x "$current" ] && "$current" --version >/dev/null 2>&1; then
    log "using downloaded node ($current)"; printf '%s' "$current"; return 0
  fi
  local shasums artifact dir
  shasums="$(curl -fsSL "$NODE_DIST_BASE/$NODE_CHANNEL/SHASUMS256.txt" 2>/dev/null || true)"
  artifact="$(printf '%s\n' "$shasums" | grep -oE "node-v[0-9]+\.[0-9]+\.[0-9]+-${node_os}-${ARCH}\.tar\.gz" | head -1 || true)"
  [ -n "$artifact" ] || { log "could not resolve a node $NODE_CHANNEL build for ${node_os}-${ARCH}"; return 1; }
  dir="${artifact%.tar.gz}"
  if curl -fsSL "$NODE_DIST_BASE/$NODE_CHANNEL/$artifact" -o "$NODE_DIR/$artifact" 2>/dev/null \
     && tar -xzf "$NODE_DIR/$artifact" -C "$NODE_DIR" 2>/dev/null; then
    ln -sfn "$NODE_DIR/$dir" "$NODE_DIR/current"
    rm -f "$NODE_DIR/$artifact" 2>/dev/null || true
    [ -x "$current" ] && "$current" --version >/dev/null 2>&1 && { log "installed node ($dir)"; printf '%s' "$current"; return 0; }
  fi
  rm -f "$NODE_DIR/$artifact" 2>/dev/null || true
  log "node download/extract failed for ${node_os}-${ARCH}"
  return 1
}

# Resolve CLI_SPEC to a concrete version. A purely numeric/dotted spec is used as-is.
# Otherwise (a dist-tag like "latest" or a range) we ask the registry EVERY session, so
# the runner tracks the newest published version, falling back to the last resolved
# version when offline.
resolve_cli_version() {
  case "$CLI_SPEC" in
    *[!0-9.]*) ;;                              # tag/range — resolve below
    *) printf '%s' "$CLI_SPEC"; return 0 ;;    # looks like X.Y.Z
  esac
  local v
  v="$(HOME="$ZH" npm_config_cache="$NPM_CACHE" PATH="$NODE_BIN_DIR:$PATH" "$NPM_BIN" view "$CLI_PKG@$CLI_SPEC" version 2>/dev/null | tail -1 || true)"
  if [ -n "$v" ]; then
    printf '%s' "$v" >"$RESOLVED_VERSION_FILE"
    printf '%s' "$v"; return 0
  fi
  [ -s "$RESOLVED_VERSION_FILE" ] && { cat "$RESOLVED_VERSION_FILE"; return 0; }
  printf '%s' "$CLI_SPEC"   # last resort: let npm interpret the tag at install time
}

# --- resolve node (+ its npm) ---
NODE_BIN=""
if [ -n "$OS_KIND" ] && [ -n "$ARCH" ]; then
  NODE_BIN="$(resolve_node || true)"
fi
if [ -z "$NODE_BIN" ]; then
  log "no usable Node runtime"
  fail "Zero runner unavailable: no Node runtime and none could be downloaded (or no network egress). ZERO_RUNNER is unset — tell the user Zero isn't available in this environment rather than improvising." \
       "no usable Node runtime found, and none could be downloaded (check network egress)"
fi
NODE_BIN_DIR="$(dirname "$NODE_BIN")"
NPM_BIN="$NODE_BIN_DIR/npm"
[ -x "$NPM_BIN" ] || NPM_BIN="$(command -v npm 2>/dev/null || true)"

mkdir -p "$ZH" "$BIN_DIR" "$CLI_DIR" "$NPM_CACHE"

# --- keep the host plugin installs fresh (background, daily, best-effort) ---
# The CLI below is refreshed every session, but the *plugin layer* (skill, hooks,
# manifest) only updates when the host's marketplace machinery runs — which most users
# never enable. So once a day, refresh every Zero install on the machine through each
# host's own front-door commands; never by writing into host-owned plugin dirs:
#   Claude Code - marketplace update, then plugin update (both required: plugin update
#                 resolves against the local catalog clone; applies next session)
#   Codex       - marketplace upgrade, then plugin add (upgrade re-resolves the plugin
#                 from the snapshot; add is idempotent and syncs the version cache)
# Gemini is deliberately NOT swept: `gemini extensions update` re-prompts for interactive
# consent whenever an update changes hooks/skills/MCP (and has no --consent flag), and a
# hook auto-answering a security prompt would be a consent bypass. Gemini freshness comes
# from its native `extensions install --auto-update` instead (see the README).
# We sweep every host CLI on PATH instead of detecting the current host: plugin installs
# are machine-global (like ~/.zero itself), so whichever host opens a session first
# freshens all of them, and absent CLIs / not-installed plugins fail quietly. The job is
# detached with all fds redirected so SessionStart never waits on it and the stdout JSON
# contract holds. The stamp is written before the attempt so a failing/offline day
# retries tomorrow rather than hammering every session. Opt out: ZERO_PLUGIN_AUTOUPDATE=0.
PLUGIN_UPDATE_STAMP="$ZH/.plugin-update-day"
if [ "$INSTALL_MODE" = "0" ] && [ "${ZERO_PLUGIN_AUTOUPDATE:-1}" != "0" ]; then
  TODAY="$(date +%Y-%m-%d)"
  if [ "$(cat "$PLUGIN_UPDATE_STAMP" 2>/dev/null || true)" != "$TODAY" ]; then
    printf '%s' "$TODAY" >"$PLUGIN_UPDATE_STAMP"
    log "refreshing host plugin installs in the background (daily; ZERO_PLUGIN_AUTOUPDATE=0 disables)"
    {
      command -v claude >/dev/null 2>&1 && { claude plugin marketplace update zero-plugins && claude plugin update zero@zero-plugins; } || true
      command -v codex >/dev/null 2>&1 && { codex plugin marketplace upgrade zero-plugins && codex plugin add zero@zero-plugins; } || true
    } </dev/null >/dev/null 2>&1 &
  fi
fi

# --- install / refresh the CLI (throttled) ---
VERSION="$(resolve_cli_version)"
INSTALLED="$(cat "$INSTALLED_VERSION_FILE" 2>/dev/null || true)"
if [ ! -f "$CLI_ENTRY" ] || [ "$INSTALLED" != "$VERSION" ]; then
  if [ -n "$NPM_BIN" ] && HOME="$ZH" npm_config_cache="$NPM_CACHE" PATH="$NODE_BIN_DIR:$PATH" "$NPM_BIN" install \
        --prefix "$CLI_DIR" "$CLI_PKG@$VERSION" \
        --no-audit --no-fund --loglevel=error >&2 2>&1; then
    printf '%s' "$VERSION" >"$INSTALLED_VERSION_FILE"
    log "installed $CLI_PKG@$VERSION into $CLI_DIR"
  else
    log "npm install of $CLI_PKG@$VERSION failed"
  fi
fi

if [ ! -f "$CLI_ENTRY" ]; then
  fail "Zero runner unavailable: $CLI_PKG@$VERSION could not be installed (likely no npm-registry egress on first run). ZERO_RUNNER is unset — tell the user Zero isn't available here rather than improvising." \
       "$CLI_PKG@$VERSION could not be installed (likely no npm-registry egress)"
fi

# --- write the shim (regenerated each session so node/version changes take effect) ---
# Runs the installed CLI directly on the resolved Node. $HOME is deliberately NOT
# overridden, so the CLI reads/writes the user's real ~/.zero/config.json — one login
# shared with the standalone CLI and skill.md-only agents. The runtime stays contained
# in $ZH via the explicit install --prefix and npm_config_cache, not via $HOME.
# NODE_BIN_DIR is on PATH so the CLI can spawn node/subprocesses. Auth comes from the
# exchanged ZERO_SESSION_TOKEN (passed in the environment), the persisted ~/.zero
# session, or an explicit ZERO_PRIVATE_KEY (BYO).
cat >"$SHIM_PATH" <<SHIM
#!/usr/bin/env sh
# Zero runner shim (generated by the zero plugin's SessionStart hook).
exec env npm_config_cache="$NPM_CACHE" PATH="$NODE_BIN_DIR:\$PATH" "$NODE_BIN" "$CLI_ENTRY" "\$@"
SHIM
chmod +x "$SHIM_PATH" 2>/dev/null || true

persist_env ZERO_RUNNER "$SHIM_PATH"

# --- put `zero` on PATH (idempotent; opt out: ZERO_PATH_AUTOADD=0) ---
# Two audiences:
#   - This session, on hosts with an env-persistence file (Claude Code): prepend
#     $BIN_DIR via $CLAUDE_ENV_FILE so bare `zero` resolves immediately.
#   - Everything else on the machine — including hosts with no env injection at all
#     (e.g. Gemini CLI) — gets a PATH line appended to the user's shell rc, the same
#     way the retired pre-1.0 install.sh handled ~/.zero/bin. New shells, and any
#     agent launched from them, then resolve bare `zero` without $ZERO_RUNNER.
# The rc edit is keyed on the runtime-bin dir substring so it's written at most once,
# and a write failure degrades to a logged hint — it never blocks the session.
RC_PATH_ADDED=""
if [ "${ZERO_PATH_AUTOADD:-1}" != "0" ]; then
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    printf 'export PATH=%q":$PATH"\n' "$BIN_DIR" >> "$CLAUDE_ENV_FILE"
  fi

  # Write the rc line $HOME-relative so it survives dotfile sync across machines;
  # grep for the $HOME-stripped form so either spelling counts as already-present.
  RC_DIR_REF="$BIN_DIR"; RC_GREP="$BIN_DIR"
  case "$BIN_DIR" in
    "$HOME"/*) RC_DIR_REF="\$HOME/${BIN_DIR#"$HOME"/}"; RC_GREP="${BIN_DIR#"$HOME"/}" ;;
  esac
  PATH_LINE="export PATH=\"$RC_DIR_REF:\$PATH\""

  add_path_to_rc() {
    local rc="$1"
    if [ -f "$rc" ] && grep -qF "$RC_GREP" "$rc" 2>/dev/null; then
      return 0
    fi
    if printf '\n# Zero runner (added by the zero plugin SessionStart hook)\n%s\n' "$PATH_LINE" >>"$rc" 2>/dev/null; then
      log "added $BIN_DIR to PATH in $rc (takes effect in new shells)"
      RC_PATH_ADDED="$rc"
    else
      log "could not write $rc — add to PATH manually: $PATH_LINE"
    fi
  }

  case "$(basename "${SHELL:-}")" in
    zsh)  add_path_to_rc "$HOME/.zshrc" ;;
    bash)
      if [ -f "$HOME/.bash_profile" ]; then
        add_path_to_rc "$HOME/.bash_profile"
      else
        add_path_to_rc "$HOME/.bashrc"
      fi
      ;;
    *)    log "unrecognized shell '${SHELL:-}' — to put zero on PATH add: $PATH_LINE" ;;
  esac
fi

INSTALLED_VERSION="$(cat "$INSTALLED_VERSION_FILE" 2>/dev/null || printf '%s' "$VERSION")"

if [ "$INSTALL_MODE" = "0" ]; then
  emit "Zero runner ready: ZERO_RUNNER=$SHIM_PATH — a drop-in for the zero CLI ($CLI_PKG@$INSTALLED_VERSION), also placed on PATH as plain \`zero\` (immediately on hosts that persist hook env; in new shells elsewhere). Use it for the whole Zero loop (search/get/fetch/review), and follow the bundled 'zero' skill for the workflow and authentication — don't improvise auth or create a wallet."
  exit 0
fi

# --- install mode: copy the skill, then a human summary instead of the JSON object ---
# The skill goes to the portable ~/.agents/skills/ directory (the agentskills.io
# convention nearly every skills-capable harness reads). Source it from the checkout
# next to this script when running from the repo/plugin; otherwise (curl | bash, where
# BASH_SOURCE is empty) fetch the published copy from the marketplace repo's main.
SKILL_DIR="${ZERO_SKILL_DIR:-$HOME/.agents/skills/zero}"
SKILL_RAW_URL="https://raw.githubusercontent.com/officialzeroxyz/zero-plugins/main/plugins/zero/skills/zero/SKILL.md"
SKILL_STATUS="not installed"
LOCAL_SKILL=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  LOCAL_SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/../skills/zero/SKILL.md"
fi
if mkdir -p "$SKILL_DIR" 2>/dev/null; then
  if [ -n "$LOCAL_SKILL" ] && [ -f "$LOCAL_SKILL" ]; then
    cp "$LOCAL_SKILL" "$SKILL_DIR/SKILL.md" && SKILL_STATUS="$SKILL_DIR/SKILL.md (from local checkout)"
  elif curl -fsSL "$SKILL_RAW_URL" -o "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    SKILL_STATUS="$SKILL_DIR/SKILL.md"
  else
    SKILL_STATUS="not installed — fetch failed; get it from $SKILL_RAW_URL"
  fi
fi

if [ -n "$RC_PATH_ADDED" ]; then
  PATH_STATUS="added to $RC_PATH_ADDED — open a new terminal or run: source \"$RC_PATH_ADDED\""
elif [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
  PATH_STATUS="already on PATH"
else
  PATH_STATUS="already configured in your shell rc (new shells pick it up)"
fi

cat <<SUMMARY

Zero installed.

  runner   $SHIM_PATH  ($CLI_PKG@$INSTALLED_VERSION)
  PATH     $PATH_STATUS
  skill    $SKILL_STATUS

Next: sign in with \`zero auth login\` (it prints a URL to approve in your browser).
SUMMARY
exit 0
