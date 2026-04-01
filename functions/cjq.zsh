cjq() {
  if ! command -v copyq &>/dev/null; then
    echo "cjq requires copyq"
    return 1
  fi

  local save=false
  local jq_args=()
  for arg in "$@"; do
    case "$arg" in
      -s|--save-to-cb) save=true ;;
      *) jq_args+=("$arg") ;;
    esac
  done
  copyq read 0 | jq -C "${jq_args[@]}"
  if $save; then
    copyq read 0 | jq "${jq_args[@]}" | copyq copy -
    echo "(saved to clipboard)"
  fi
}
