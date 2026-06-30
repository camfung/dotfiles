#!/bin/bash
# Custom statusline: git branch · effort · context · session-start time
# Reads the statusLine JSON payload from stdin (see code.claude.com/docs/en/statusline).
input=$(cat)

DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // "."')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
MODEL=$(echo "$input" | jq -r '.model.display_name // empty')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DUR_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LIMIT_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
LIMIT_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Per-segment palette: colored background + white text ("blocks").
# (24-bit truecolor; needs a truecolor terminal e.g. kitty.)
FG='\033[38;2;0;0;0m'               # black foreground for every block
C_DIR='\033[48;2;0;141;213m'        # 008DD5  blue   bg
C_BRANCH='\033[48;2;233;79;55m'     # E94F37  red    bg
C_EFFORT='\033[48;2;255;231;76m'    # FFE74C  yellow bg
C_CTX='\033[48;2;0;255;65m'         # 00FF41  green  bg
C_TIME='\033[48;2;255;140;0m'       # FF8C00  orange bg
C_LIMIT='\033[48;2;148;87;235m'     # 9457EB  violet bg
RESET='\033[0m'
BOLD='\033[1m'

# --- project dir (directory the session was opened in) ---
DIR_SEG="${C_DIR}${FG} ${PROJECT_DIR##*/} ${RESET}"

# --- git: branch + dirty marker ---
GIT_SEG=""
if BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null) && [ -n "$BRANCH" ]; then
    DIRTY=""
    [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ] && DIRTY="*"
    GIT_SEG="${C_BRANCH}${FG} ${BRANCH}${DIRTY} ${RESET}"
fi

# --- model-effort (model shortened: first letter + version number, e.g. "Opus 4.8" -> "O4.8") ---
EFFORT_SEG=""
LABEL=""
if [ -n "$MODEL" ]; then
    LETTER=$(printf '%.1s' "$MODEL")
    NUM=$(echo "$MODEL" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    LABEL="${LETTER}-${NUM}"
fi
[ -n "$EFFORT" ] && LABEL="${LABEL:+$LABEL-}${EFFORT}"
[ -n "$LABEL" ] && EFFORT_SEG="${C_EFFORT}${FG} ${LABEL} ${RESET}"

# --- context: 5-dot bar (quarter-filled steps) ---
BAR=""
for i in $(seq 1 5); do
    FULL=$((i * 20))
    if [ "$PCT" -ge "$FULL" ]; then cell="●"
    elif [ "$PCT" -ge $((FULL - 5)) ]; then cell="◕"
    elif [ "$PCT" -ge $((FULL - 10)) ]; then cell="◑"
    elif [ "$PCT" -ge $((FULL - 15)) ]; then cell="◔"
    else cell="○"; fi
    [ -z "$BAR" ] && BAR="$cell" || BAR="${cell} ${BAR}"
done
CTX_SEG="${C_CTX}${FG} ${BOLD}${BAR}${RESET}${C_CTX}${FG} ${PCT}% ${RESET}"

# --- 5-hour window usage limit (Pro/Max only; absent until first API response) ---
LIMIT_SEG=""
if [ -n "$LIMIT_PCT" ]; then
    RESET_STR=""
    [ -n "$LIMIT_RESET" ] && RESET_STR=" ↻$(date -d "@${LIMIT_RESET}" +%H:%M 2>/dev/null)"
    LIMIT_SEG="${C_LIMIT}${FG} ${LIMIT_PCT}%${RESET_STR} ${RESET}"
fi

# --- session start time (now - wall-clock duration) ---
START_EPOCH=$(( $(date +%s) - DUR_MS / 1000 ))
START_TIME=$(date -d "@${START_EPOCH}" +%H:%M 2>/dev/null)
TIME_SEG="${C_TIME}${FG} ${START_TIME} ${RESET}"

# --- assemble (skip empty segments) ---
SEP=""
OUT=""
# ROYGBIV: red branch, orange time, yellow effort, green context, blue dir, violet limit
for seg in "$GIT_SEG" "$TIME_SEG" "$EFFORT_SEG" "$CTX_SEG" "$DIR_SEG" "$LIMIT_SEG"; do
    [ -z "$seg" ] && continue
    [ -n "$OUT" ] && OUT="${OUT}${SEP}"
    OUT="${OUT}${seg}"
done
echo -e "$OUT"
