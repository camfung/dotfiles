each() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
Usage: ... | each [OPTIONS] COMMAND [ARGS...]

Run COMMAND for each line of stdin. Use {} as a placeholder for the line.
If {} is omitted, the line is appended as the last argument.

Options:
  -n        Dry-run: print commands instead of executing
  -h|--help Show this help

Examples:
  fd -e json | each cp {} ./out/
  fd -e json | each echo
  fd -e json | each -n cp {} ./out/
EOF
    return 0
  fi
  local dry=false
  [[ "$1" == "-n" ]] && { dry=true; shift; }
  if [[ "$*" == *'{}'* ]]; then
    while IFS= read -r line; do
      local cmd=()
      for arg in "$@"; do cmd+=("${arg//\{\}/$line}"); done
      if $dry; then echo "${cmd[*]}"; else "${cmd[@]}"; fi
    done
  else
    while IFS= read -r line; do
      if $dry; then echo "$* $line"; else "$@" "$line"; fi
    done
  fi
}

forEach() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
Usage: ... | forEach [OPTIONS] 'COMMAND'

Run COMMAND (via eval) for each line of stdin. Use $it to reference the line.
Single-quote the command to prevent premature $it expansion.

Options:
  -n        Dry-run: print commands instead of executing
  -h|--help Show this help

Examples:
  fd -e json | forEach 'cp "$it" ./out/'
  fd -e json | forEach 'echo "Processing: $it"; wc -l "$it"'
  fd -e json | forEach -n 'cp "$it" ./out/'
EOF
    return 0
  fi
  local dry=false
  [[ "$1" == "-n" ]] && { dry=true; shift; }
  local it
  while IFS= read -r it; do
    if $dry; then eval "echo \"$@\""; else eval "$@"; fi
  done
}
