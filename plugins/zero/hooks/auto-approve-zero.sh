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
# No external tools — pure bash parameter expansion (no jq/sed/awk/node), so it runs
# anywhere bash does. We only need the executable + subcommand, which are plain words
# at the very start of the command value (before any user args that could contain
# quotes/braces), so a full JSON parse is unnecessary. Best-effort + fail-safe:
# anything we can't positively classify as a read-only zero command is left for manual
# approval. Always exits 0. stdout carries at most one PreToolUse JSON object.

set -euo pipefail

input="$(cat)"

# Must be a Bash tool call (compact or spaced JSON).
case "$input" in
  *'"tool_name":"Bash"'* | *'"tool_name": "Bash"'*) ;;
  *) exit 0 ;;
esac

# Pull the LEADING portion of the command value without a JSON parser: strip up to the
# command key, trim whitespace, require the opening quote, then keep text up to the
# first (possibly escaped) double-quote. The exe + subcommand live in that prefix.
after="${input#*\"command\":}"
[ "$after" = "$input" ] && exit 0                 # no command field → not ours
after="${after#"${after%%[![:space:]]*}"}"        # trim leading whitespace
case "$after" in \"*) after="${after#\"}" ;; *) exit 0 ;; esac # require opening quote
lead="${after%%\"*}"                              # text before the first quote
lead="${lead%\\}"                                 # drop a trailing backslash from \"

# Normalize stray quote/backslash chars, then tokenize on whitespace.
lead="${lead//\\/}"
lead="${lead//\'/}"
IFS=' ' read -r -a toks <<<"$lead" || true

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
  search | get | review | runs) ;;          # read-only, no payment
  config) case "$lead" in *--set*) exit 0 ;; esac ;; # only viewing config is safe
  init) ;;                                   # wallet generation only; safe to re-run
  *) exit 0 ;;                               # fetch (money), wallet (funds), unknown → manual
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Zero read-only operation auto-approved"}}
JSON
exit 0
