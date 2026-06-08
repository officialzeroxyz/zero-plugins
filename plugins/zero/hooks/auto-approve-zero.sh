#!/usr/bin/env bash
#
# Zero plugin — PreToolUse hook (Bash matcher).
#
# Auto-approves safe, read-only Zero commands to cut permission fatigue. Never
# auto-approves `fetch` (spends money) or `wallet` (manages funds) — those always
# fall through to normal manual approval. Mirrors `zero init`'s auto-approve-zero.sh
# but matches the plugin's invocation shape: the executable may be a path
# ($ZERO_RUNNER, .../bin/zero), a bare `zero`/`zerocli`, and may be preceded by env
# assignments (e.g. `ZERO_SESSION_TOKEN=... zero ...`).
#
# Reads the tool input with jq; if jq is absent we do nothing and let the command
# go through normal approval (the safe default). Conservative by construction —
# anything we can't positively classify as read-only is left for manual approval.
# Always exits 0. stdout carries at most one PreToolUse JSON object.

set -euo pipefail

# No jq → no auto-approval. Manual approval still works; that's the safe fallback.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
[ "$tool_name" = "Bash" ] || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
[ -n "$cmd" ] || exit 0

# Strip quotes the agent may have wrapped tokens in, then tokenize on whitespace.
cmd_norm="${cmd//\"/}"
cmd_norm="${cmd_norm//\'/}"
read -r -a toks <<<"$cmd_norm"

# Skip leading env assignments (VAR=value) to reach the executable token.
idx=0
while [ "$idx" -lt "${#toks[@]}" ]; do
  case "${toks[$idx]}" in
    [A-Za-z_]*=*) idx=$((idx + 1)) ;;
    *) break ;;
  esac
done

exe="${toks[$idx]:-}"
sub="${toks[$((idx + 1))]:-}"
base="${exe##*/}" # basename of the executable token

# Only Zero invocations. A literal, unexpanded "$ZERO_RUNNER" has no basename match
# and falls through to manual approval — intentional; we never guess.
case "$base" in
  zero | zerocli) ;;
  *) exit 0 ;;
esac

case "$sub" in
  search | get | review | runs) ;; # read-only, no payment
  config)
    case "$cmd" in *--set*) exit 0 ;; esac # only viewing config is safe
    ;;
  init) ;;        # wallet generation only; safe to re-run
  *) exit 0 ;;    # fetch (money), wallet (funds), or unknown → manual approval
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Zero read-only operation auto-approved"}}
JSON
exit 0
