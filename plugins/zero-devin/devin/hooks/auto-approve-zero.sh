#!/usr/bin/env bash
#
# Devin PermissionRequest hook for Zero read-only shell commands.
#
# Devin uses "exec" as the shell tool name and accepts a plain
# {"decision":"approve"} response. Keep this wrapper narrow: only approve
# read-only Zero commands, and leave fetch/wallet/unknown calls for Devin's
# normal permission flow.

set -euo pipefail

input="$(cat)"

case "$input" in
  *'"tool_name":"exec"'* | *'"tool_name": "exec"'*) ;;
  *) exit 0 ;;
esac

after="${input#*\"command\":}"
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

printf '{"decision":"approve","reason":"Zero read-only operation approved"}\n'
