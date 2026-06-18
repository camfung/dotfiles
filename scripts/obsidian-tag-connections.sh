#!/usr/bin/env bash
#
# obsidian-tag-connections.sh
#
# Apply a tag to the connections of a note in your Obsidian vault.
# "Connections" = outgoing links (files this note links to) and/or
# incoming links (backlinks — files that link to this note).
#
# Uses the built-in Obsidian CLI (`obsidian <command>`), so the Obsidian
# app must be running and the target vault open.
#
# Usage:
#   obsidian-tag-connections.sh [options] <file-path> <tag>
#
#   <file-path>  Vault-relative path to the note, e.g. "notes/index.md"
#   <tag>        Tag to apply (with or without leading '#'), e.g. "project"
#
# Options:
#   -d, --direction <outgoing|incoming|both>
#                        Which connections to tag. Default: both
#   -D, --depth <n>      Walk the link graph n hops out from the file (BFS).
#                        1 = direct connections only (default). 2 = connections
#                        of connections, etc. Visited notes are tagged once.
#   -s, --self           Also apply the tag to the target file itself
#   -n, --dry-run        Print what would change without modifying anything
#   -v, --vault <name>   Target a specific vault by name
#   -h, --help           Show this help
#
# Examples:
#   obsidian-tag-connections.sh "projects/alpha.md" inprogress
#   obsidian-tag-connections.sh -d outgoing -s "moc/areas.md" area
#   obsidian-tag-connections.sh --dry-run -d incoming "notes/seed.md" review
#   obsidian-tag-connections.sh -D 2 -d both "moc/hub.md" cluster

set -euo pipefail

# ---- defaults (configurable) -------------------------------------------------
DIRECTION="both"     # outgoing | incoming | both
INCLUDE_SELF=false   # also tag the target file
DEPTH=1              # how many hops to walk out from the target
DRY_RUN=false
VAULT=""             # empty = active vault
OBSIDIAN_BIN="${OBSIDIAN_BIN:-obsidian}"

# ---- helpers -----------------------------------------------------------------
die() { echo "error: $*" >&2; exit 1; }

usage() { sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'; }

# Run the obsidian CLI, stripping its startup banner lines from stdout.
ob() {
  local args=("$@")
  [[ -n "$VAULT" ]] && args=("vault=$VAULT" "${args[@]}")
  "$OBSIDIAN_BIN" "${args[@]}" 2>/dev/null \
    | grep -Ev '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} |^Your Obsidian installer is out of date'
}

# ---- arg parsing -------------------------------------------------------------
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--direction) DIRECTION="${2:-}"; shift 2 ;;
    -D|--depth)     DEPTH="${2:-}"; shift 2 ;;
    -s|--self)      INCLUDE_SELF=true; shift ;;
    -n|--dry-run)   DRY_RUN=true; shift ;;
    -v|--vault)     VAULT="${2:-}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; POSITIONAL+=("$@"); break ;;
    -*)             die "unknown option: $1" ;;
    *)              POSITIONAL+=("$1"); shift ;;
  esac
done

SYNOPSIS='usage: obsidian-tag-connections.sh [options] <file-path> <tag>   (-h for help)'

# Specific feedback for the wrong number of positional args.
if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
  echo "error: expected <file-path> and <tag>, got ${#POSITIONAL[@]} argument(s): ${POSITIONAL[*]:-(none)}" >&2
  if [[ ${#POSITIONAL[@]} -eq 1 ]]; then
    echo "hint: missing the <tag>, OR a path with spaces wasn't quoted." >&2
    echo "      quote it: \"${POSITIONAL[0]}\" <tag>" >&2
  fi
  echo "$SYNOPSIS" >&2
  exit 1
elif [[ ${#POSITIONAL[@]} -gt 2 ]]; then
  echo "error: too many arguments (${#POSITIONAL[@]}): ${POSITIONAL[*]}" >&2
  echo "hint: a path with spaces must be quoted, e.g. \"Daily notes/week 47/x.md\"" >&2
  echo "$SYNOPSIS" >&2
  exit 1
fi

TARGET="${POSITIONAL[0]}"
TAG="${POSITIONAL[1]#\#}"   # strip a leading '#' if present

case "$DIRECTION" in
  outgoing|incoming|both) ;;
  *) die "--direction must be outgoing|incoming|both (got: $DIRECTION)" ;;
esac

[[ "$DEPTH" =~ ^[0-9]+$ && "$DEPTH" -ge 1 ]] || die "--depth must be a positive integer (got: '$DEPTH')"

command -v "$OBSIDIAN_BIN" >/dev/null 2>&1 || die "obsidian CLI not found ($OBSIDIAN_BIN). Is Obsidian installed and on PATH?"
[[ -n "$TAG" ]] || die "tag is empty"

# Tags can't contain whitespace in Obsidian.
[[ "$TAG" =~ [[:space:]] ]] && die "tag must not contain whitespace (got: '$TAG')"

# Confirm the Obsidian CLI can reach a running vault, and the target exists.
# 'file path=' returns info for a real note and an error otherwise.
file_info="$(ob file path="$TARGET" 2>/dev/null || true)"
if [[ -z "$file_info" ]]; then
  die "cannot read vault — is Obsidian running with the target vault open? (try -v <vault>)"
fi
if [[ "$file_info" == Error:* || "$file_info" == *"not found"* ]]; then
  die "target file not found in vault: '$TARGET' (use the exact vault-relative path incl. .md)"
fi

# ---- collect connection paths (BFS to --depth hops) --------------------------
# Print the direct neighbours of a node, one vault-relative path per line,
# honouring DIRECTION. Filters the CLI status/error lines that land on stdout.
neighbors() {
  local node="$1" cmd line
  for cmd in links backlinks; do
    { [[ "$cmd" == links    && ( "$DIRECTION" == outgoing || "$DIRECTION" == both ) ]] || \
      [[ "$cmd" == backlinks && ( "$DIRECTION" == incoming || "$DIRECTION" == both ) ]]; } || continue
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # status lines arrive on stdout when there are no results
      [[ "$line" == "No links found." || "$line" == "No backlinks found." ]] && continue
      [[ "$line" == Error:* ]] && continue
      printf '%s\n' "$line"
    done < <(ob "$cmd" path="$node")
  done
}

declare -A SEEN=()       # files to tag
declare -A VISITED=()    # nodes already enqueued (cycle guard)
VISITED["$TARGET"]=1
frontier=("$TARGET")
level=0
while [[ $level -lt $DEPTH && ${#frontier[@]} -gt 0 ]]; do
  next=()
  for node in "${frontier[@]}"; do
    while IFS= read -r nb; do
      [[ -z "$nb" ]] && continue
      [[ -n "${VISITED[$nb]:-}" ]] && continue
      VISITED["$nb"]=1
      SEEN["$nb"]=1
      next+=("$nb")
    done < <(neighbors "$node")
  done
  frontier=()
  [[ ${#next[@]} -gt 0 ]] && frontier=("${next[@]}")
  level=$((level + 1))
done

[[ "$INCLUDE_SELF" == true ]] && SEEN["$TARGET"]=1

if [[ ${#SEEN[@]} -eq 0 ]]; then
  echo "No ${DIRECTION} connections found for: $TARGET"
  exit 0
fi

# ---- apply tag to each connection -------------------------------------------
apply_tag() {
  local path="$1"
  # only touch markdown notes
  [[ "$path" == *.md ]] || { echo "skip (not md): $path"; return; }

  # read existing tags (one per line).
  # property:read prints 'Error: Property "tags" not found' when the note has
  # no tags yet (exit code is still 0), and that line can reach stdout. Tags
  # never contain whitespace, so drop error/non-tag lines defensively.
  local existing=() t
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    [[ "$t" == Error:* ]] && continue
    [[ "$t" =~ [[:space:]] ]] && continue
    existing+=("$t")
  done < <(ob property:read name=tags path="$path" || true)

  # already tagged?
  for t in "${existing[@]:-}"; do
    if [[ "$t" == "$TAG" ]]; then
      echo "already tagged: $path"
      return
    fi
  done

  # merge + dedupe, then write as a list
  local merged=("${existing[@]:-}" "$TAG")
  local joined
  joined=$(printf '%s\n' "${merged[@]}" | awk 'NF' | awk '!seen[$0]++' | paste -sd, -)

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $path : tags -> $joined"
    return
  fi

  ob property:set name=tags value="$joined" type=list path="$path" >/dev/null
  echo "tagged: $path  (+$TAG)"
}

echo "Tagging ${#SEEN[@]} ${DIRECTION} connection(s) of '$TARGET' (depth $DEPTH) with '#$TAG'"
for p in "${!SEEN[@]}"; do
  apply_tag "$p"
done
