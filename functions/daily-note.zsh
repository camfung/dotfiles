# Export $DAILY_NOTE — absolute path to the current Obsidian daily note.
# startDay.sh writes the path to $OBSIDIAN_VAULT/.current-daily-note on each run.
# This precmd hook re-reads it before every prompt so new AND already-open
# terminals stay in sync (env vars can't be pushed into running shells).
autoload -Uz add-zsh-hook

_update_daily_note() {
  local state="${OBSIDIAN_VAULT}/.current-daily-note"
  [[ -n "$OBSIDIAN_VAULT" && -r "$state" ]] && export DAILY_NOTE="$(<"$state")"
}
add-zsh-hook precmd _update_daily_note

# dn — operate on the current daily note.
#   dn            edit in $EDITOR
#   dn cd         cd into its directory
#   dn cat        print it
#   dn path       print its path
#   dn add <txt>  append a line
dn() {
  _update_daily_note
  if [[ -z "$DAILY_NOTE" || ! -e "$DAILY_NOTE" ]]; then
    print -u2 "no current daily note — run startday"
    return 1
  fi
  case "$1" in
    "")    ${EDITOR:-vim} "$DAILY_NOTE" ;;
    cd)    cd "${DAILY_NOTE:h}" ;;
    cat)   cat "$DAILY_NOTE" ;;
    path)  print -r -- "$DAILY_NOTE" ;;
    add)   shift; print -r -- "$*" >> "$DAILY_NOTE" ;;
    *)     print -u2 "usage: dn [cd|cat|path|add <text>]"; return 1 ;;
  esac
}
