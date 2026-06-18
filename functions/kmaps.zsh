# List the keyboard shortcuts defined in the kitty config.
# Parses `map` directives live on every run (following `include` files),
# so kitty.conf stays the single source of truth — add a binding there and
# it shows up here with no second place to update.
kmaps() {
  if [[ "$1" == -h || "$1" == --help ]]; then
    print -r -- 'kmaps — list the keyboard shortcuts defined in your kitty config

Usage: kmaps [-h|--help]

Parses `map` directives from kitty.conf live on every run (following any
`include`/`globinclude` files), so the config stays the single source of
truth — add a binding there and it shows up here, no second place to edit.

Reads:  ${KITTY_CONFIG_DIRECTORY:-~/.config/kitty}/kitty.conf
Output: humanized keys (ctrl+shift+l -> Ctrl+Shift+L), aligned, color on a tty.'
    return 0
  fi

  local conf_dir="${KITTY_CONFIG_DIRECTORY:-$HOME/.config/kitty}"
  local root="$conf_dir/kitty.conf"

  if [[ ! -r "$root" ]]; then
    print -u2 "kmaps: cannot read kitty config at $root"
    return 1
  fi

  # Resolve the full include tree into an ordered, de-duplicated file list.
  local -a files queue=("$root")
  local -A seen
  local f dir inc
  while (( ${#queue} )); do
    f="${queue[1]}"
    queue=("${queue[@]:1}")
    [[ -r "$f" && -z "${seen[$f]}" ]] || continue
    seen[$f]=1
    files+=("$f")
    dir="${f:h}"
    while IFS= read -r inc; do
      [[ "$inc" == /* ]] || inc="$dir/$inc"
      queue+=( ${~inc} )   # expand globs from glob/include targets
    done < <(grep -E '^[[:space:]]*(glob)?include[[:space:]]' "$f" 2>/dev/null \
             | sed -E 's/^[[:space:]]*(glob)?include[[:space:]]+//')
  done

  local color=0
  [[ -t 1 ]] && color=1

  awk -v color="$color" '
    function humanize(k,   seq, n, i, sp, m, j, tok, chord, out) {
      n = split(k, seq, ">")            # ">" denotes a chord sequence
      out = ""
      for (i = 1; i <= n; i++) {
        m = split(seq[i], sp, "+")
        chord = ""
        for (j = 1; j <= m; j++) {
          tok = sp[j]
          if (length(tok) == 1) tok = toupper(tok)
          else tok = toupper(substr(tok, 1, 1)) substr(tok, 2)
          chord = chord (j > 1 ? "+" : "") tok
        }
        out = out (i > 1 ? " then " : "") chord
      }
      return out
    }
    $1 == "map" {
      keys = $2
      action = ""
      for (i = 3; i <= NF; i++) action = action (i > 3 ? " " : "") $i
      if (action == "") action = "(unmapped)"
      hk = humanize(keys)
      n++; K[n] = hk; A[n] = action
      if (length(hk) > w) w = length(hk)
    }
    END {
      if (n == 0) { print "  (no key bindings found)"; exit }
      cyan = color ? "\033[36m" : ""
      dim  = color ? "\033[2m"  : ""
      rst  = color ? "\033[0m"  : ""
      for (i = 1; i <= n; i++)
        printf "  %s%-*s%s  %s%s%s\n", cyan, w, K[i], rst, dim, A[i], rst
      printf "\n  %d binding%s\n", n, (n == 1 ? "" : "s")
    }
  ' "${files[@]}"
}
