#!/usr/bin/env bash
#
# Crush PreToolUse hook for Zero runner commands.
# - Allow read-only Zero commands.
# - Block zero fetch without an explicit --max-pay cap.
# - Leave spending commands and unknown commands to Crush's normal permission flow.

set -euo pipefail

cmd="${CRUSH_TOOL_INPUT_COMMAND:-}"

context_json='"Zero is available through the zero skill and runner. Use search, inspect, fetch with an explicit --max-pay cap, then review successful paid runs when appropriate."'

trimmed="${cmd#"${cmd%%[![:space:]]*}"}"
read -r -a toks <<<"$trimmed" || true

idx=0
while [ "$idx" -lt "${#toks[@]}" ]; do
  case "${toks[$idx]}" in
    [A-Za-z_][A-Za-z0-9_]*=*) idx=$((idx + 1)) ;;
    *) break ;;
  esac
done

exe="${toks[$idx]:-}"
sub="${toks[$((idx + 1))]:-}"
base="${exe##*/}"

case "$base" in
  zero | zerocli) ;;
  *)
    printf '{"context":%s}\n' "$context_json"
    exit 0
    ;;
esac

case "$sub" in
  search | get | runs | review)
    printf '{"decision":"allow","context":%s}\n' "$context_json"
    ;;
  auth)
    if [ "${toks[$((idx + 2))]:-}" = "whoami" ]; then
      printf '{"decision":"allow","context":%s}\n' "$context_json"
    else
      printf '{"context":%s}\n' "$context_json"
    fi
    ;;
  config)
    case "$cmd" in
      *"--set"*) printf '{"context":%s}\n' "$context_json" ;;
      *) printf '{"decision":"allow","context":%s}\n' "$context_json" ;;
    esac
    ;;
  fetch)
    case "$cmd" in
      *"--max-pay"*) printf '{"context":%s}\n' "$context_json" ;;
      *)
        printf '{"decision":"deny","reason":"Zero fetch commands must include an explicit --max-pay cap.","context":%s}\n' "$context_json"
        ;;
    esac
    ;;
  *)
    printf '{"context":%s}\n' "$context_json"
    ;;
esac
