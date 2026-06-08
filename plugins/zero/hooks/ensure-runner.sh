#!/usr/bin/env bash
#
# Zero plugin — SessionStart hook.
#
# Provisions a Zero "runner" so the agent can call paid capabilities directly in its
# own environment, exports its path as $ZERO_RUNNER for the session, and tells the
# agent — via the SessionStart `additionalContext` payload — how to authenticate.
#
# Runner model: the runner IS the published @zeroxyz/cli npm package (a single
# bundled, zero-dependency file as of 0.0.44), run on Node. We install it once per
# session into a SHARED home and point a one-line shim at the installed entry, so
# $ZERO_RUNNER stays a single path and per-call overhead is just Node startup
# (~200ms) — not an npx resolve (~1s). The same code runs on Windows, macOS, Linux,
# and cloud sandboxes; only how we obtain Node varies:
#   a. system `node` (>= min major) on PATH if present — nothing is downloaded; else
#   b. download an official Node build (which bundles npm) into the shared home, once.
#
# Shared home: everything lands under $HOME/.zero-plugins — Node, the npm/npx cache,
# the installed CLI, the shim, and the CLI's own config dir (.zero/config.json). This
# is DELIBERATELY shared across every host's Zero plugin (Claude Code, Codex, …) so a
# local-wallet / CLI credential set once is read by all of them (cross-agent), and is
# DELIBERATELY separate from the standalone CLI's ~/.zero so existing CLI users are
# never touched. A shared dir is not removed on a single plugin's uninstall.
#
# Auth: the agent never creates a wallet. For ephemeral/sandbox environments it mints
# a short-lived credential via the Zero MCP connector's begin_session tool; for
# persistent environments a local/BYO credential under the shared home is preferred.
# An explicit ZERO_PRIVATE_KEY is honored for bring-your-own signing.
#
# Contract: the ONLY thing written to stdout is a single SessionStart JSON object. All
# human/log output goes to stderr. Always exits 0 — a failed provisioning step
# degrades to a clear "unavailable" message rather than blocking the session.

set -euo pipefail

# --- Config (override via env) ---
# Host detection FIRST: Codex exports a neutral PLUGIN_ROOT alongside CLAUDE_PLUGIN_ROOT;
# Claude Code sets only CLAUDE_PLUGIN_ROOT. Capture it before we reuse PLUGIN_ROOT below
# as a plain path var. Used to emit host-correct auth guidance.
HOST="claude"; [ -n "${PLUGIN_ROOT:-}" ] && HOST="codex"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# Shared, cross-agent runner home — separate from the standalone CLI's ~/.zero.
ZH="${ZERO_PLUGINS_HOME:-$HOME/.zero-plugins}"

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
# How often (minutes) we re-check the registry for a newer CLI version and re-validate
# the runner. Between checks we use the installed copy with no network. Default 24h.
RUNNER_REFRESH_TTL_MIN="${ZERO_RUNNER_REFRESH_TTL_MIN:-1440}"

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

# Append `export NAME=value` to the session env file so it persists for the session
# (Claude Code only — no-op elsewhere, e.g. Codex has no env-persistence file).
persist_env() {
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    printf 'export %s=%q\n' "$1" "$2" >> "$CLAUDE_ENV_FILE"
  fi
}

# Host-correct auth guidance for when begin_session reports the connector isn't authorized.
if [ "$HOST" = "codex" ]; then
  AUTH_FLOW="If begin_session is unavailable or errors that the connector isn't authorized, the Zero MCP connector needs OAuth: tell the user to run 'codex mcp login zero' in their terminal to authorize it, then retry. Do not create or use a local wallet."
else
  AUTH_FLOW="If begin_session is unavailable or errors that the connector isn't authorized, start the OAuth flow by CALLING the connector's authenticate tool (in Claude Code: mcp__plugin_zero_zero__authenticate) — it returns an authorization URL; share it with the user to approve in their browser. On a local session the connector's tools then activate automatically; on a remote/sandbox session, have the user paste the resulting localhost callback URL into complete_authentication. Do NOT just tell the user to open /mcp settings, and do not create or use a local wallet."
fi

# A throttled freshness check: returns 0 (fresh) if $1 was touched within TTL minutes.
is_fresh() {
  [ -e "$1" ] && find "$1" -mmin "-$RUNNER_REFRESH_TTL_MIN" 2>/dev/null | grep -q .
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
# Otherwise (a dist-tag like "latest" or a range) we ask the registry, throttled, and
# fall back to the last resolved version when offline.
resolve_cli_version() {
  case "$CLI_SPEC" in
    *[!0-9.]*) ;;                              # tag/range — resolve below
    *) printf '%s' "$CLI_SPEC"; return 0 ;;    # looks like X.Y.Z
  esac
  if is_fresh "$RESOLVED_VERSION_FILE" && [ -s "$RESOLVED_VERSION_FILE" ]; then
    cat "$RESOLVED_VERSION_FILE"; return 0
  fi
  local v
  v="$(HOME="$ZH" npm_config_cache="$NPM_CACHE" "$NPM_BIN" view "$CLI_PKG@$CLI_SPEC" version 2>/dev/null | tail -1 || true)"
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
  emit "Zero's runner could not be provisioned (no Node runtime and none could be downloaded, or no network egress). ZERO_RUNNER is unset. Tell the user Zero is unavailable in this environment rather than guessing — the MCP connector only mints credentials (begin_session); it cannot run capabilities on its own."
  exit 0
fi
NODE_BIN_DIR="$(dirname "$NODE_BIN")"
NPM_BIN="$NODE_BIN_DIR/npm"
[ -x "$NPM_BIN" ] || NPM_BIN="$(command -v npm 2>/dev/null || true)"

mkdir -p "$ZH" "$BIN_DIR" "$CLI_DIR" "$NPM_CACHE"

# --- install / refresh the CLI (throttled) ---
VERSION="$(resolve_cli_version)"
INSTALLED="$(cat "$INSTALLED_VERSION_FILE" 2>/dev/null || true)"
if [ ! -f "$CLI_ENTRY" ] || [ "$INSTALLED" != "$VERSION" ] || ! is_fresh "$INSTALLED_VERSION_FILE"; then
  if [ -n "$NPM_BIN" ] && HOME="$ZH" npm_config_cache="$NPM_CACHE" "$NPM_BIN" install \
        --prefix "$CLI_DIR" "$CLI_PKG@$VERSION" \
        --no-audit --no-fund --loglevel=error >&2 2>&1; then
    printf '%s' "$VERSION" >"$INSTALLED_VERSION_FILE"
    log "installed $CLI_PKG@$VERSION into $CLI_DIR"
  else
    log "npm install of $CLI_PKG@$VERSION failed"
  fi
fi

if [ ! -f "$CLI_ENTRY" ]; then
  emit "Zero's runner could not be installed ($CLI_PKG@$VERSION). ZERO_RUNNER is unset. Likely no network egress to the npm registry on first run. Tell the user Zero is unavailable here rather than guessing."
  exit 0
fi

# --- write the shim (regenerated each session so node/version changes take effect) ---
# Runs the installed CLI directly on the resolved Node with an isolated, shared HOME so
# the CLI's config dir is $ZH/.zero (never the user's ~/.zero). NODE_BIN_DIR is on PATH
# so the CLI can spawn node/subprocesses. Auth comes from the MCP-minted session
# credential (passed in the environment) or an explicit ZERO_PRIVATE_KEY (BYO).
cat >"$SHIM_PATH" <<SHIM
#!/usr/bin/env sh
# Zero runner shim (generated by the zero plugin's SessionStart hook).
exec env HOME="$ZH" npm_config_cache="$NPM_CACHE" PATH="$NODE_BIN_DIR:\$PATH" "$NODE_BIN" "$CLI_ENTRY" "\$@"
SHIM
chmod +x "$SHIM_PATH" 2>/dev/null || true

persist_env ZERO_RUNNER "$SHIM_PATH"

INSTALLED_VERSION="$(cat "$INSTALLED_VERSION_FILE" 2>/dev/null || printf '%s' "$VERSION")"
emit "Zero runner is ready: ZERO_RUNNER=$SHIM_PATH is a drop-in for the zero CLI ($CLI_PKG@$INSTALLED_VERSION, installed under the shared $ZH home; auto-updates on the next session about every ${RUNNER_REFRESH_TTL_MIN} minutes). Run the whole loop through it: \$ZERO_RUNNER search \"<query>\", then get, fetch, review. For ephemeral/sandbox sessions, authenticate ONLY by minting a credential with the Zero MCP tool begin_session and passing it to the runner in the environment (the bundled CLI reads ZERO_SESSION_CODE). ${AUTH_FLOW} NEVER run 'zero init', 'zero auth login', 'zero wallet', or 'zero welcome', and never mention a welcome bonus. An explicit ZERO_PRIVATE_KEY is honored for bring-your-own signing, but never create a wallet yourself. The runner uses the shared, plugin-owned config dir $ZH/.zero (not your ~/.zero), so it never picks up the standalone CLI's wallet. begin_session is the only MCP tool you call; search, get, fetch and review all go through the runner."
exit 0
