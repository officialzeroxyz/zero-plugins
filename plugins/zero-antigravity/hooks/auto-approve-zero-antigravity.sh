#!/usr/bin/env bash
#
# Antigravity PreToolUse hook.
#
# Auto-approves safe, read-only Zero commands in Antigravity's camelCase hook
# contract. Paid calls (`zero fetch`) and wallet/funding commands are left for
# normal review.

set -euo pipefail

input="$(cat)"

case "$input" in
  *'"name":"run_command"'* | *'"name": "run_command"'*) ;;
  *) exit 0 ;;
esac

after="${input#*\"CommandLine\":}"
[ "$after" = "$input" ] && exit 0
after="${after#"${after%%[![:space:]]*}"}"
case "$after" in \"*) after="${after#\"}" ;; *) exit 0 ;; esac
lead="${after%%\"*}"
lead="${lead%\\}"

lead="${lead//\\/}"
lead="${lead//\'/}"
IFS=' ' read -r -a toks <<<"$lead" || true

idx=0
while [ "$idx" -lt "${#toks[@]}" ]; do
  case "${toks[$idx]}" in
    [A-Za-z_]*=*) idx=$((idx + 1)) ;;
    *) break ;;
  esac
done

exe="${toks[$idx]:-}"
sub="${toks[$((idx + 1))]:-}"
base="${exe##*/}"

case "$base" in
  zero | zerocli) ;;
  *) exit 0 ;;
esac

case "$sub" in
  search | get | review | runs) ;;
  config) case "$lead" in *--set*) exit 0 ;; esac ;;
  init) ;;
  *) exit 0 ;;
esac

cat <<'JSON'
{"decision":"allow","reason":"Zero read-only operation auto-approved"}
JSON
