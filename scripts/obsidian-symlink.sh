#!/bin/bash
# PostToolUse hook: symlink files created by Write into Obsidian daily note

PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/Documents/Projects}"
VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-vault}"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<'EOF'
Usage: obsidian-symlink.sh

PostToolUse hook that symlinks files created by the Write tool into the
Obsidian daily note folder and logs the action per-project.

  - Reads the current week from $OBSIDIAN_VAULT/current-week.txt
  - Derives project name from cwd (first child of $PROJECTS_ROOT/)
  - Creates a symlink in:  Daily notes/week {W}/{DATE}/claude/{project}/
  - Appends an entry to:   Daily notes/week {W}/{DATE}/claude-log_{project}_{DATE}.md
  - Falls back to "misc" for work outside the Projects directory

Skipped paths: obsidian-vault/*, node_modules/*, .git/*, __pycache__/*

Options:
  -h, --help    Show this help message and exit
EOF
  exit 0
fi

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

[ -z "$file_path" ] && exit 0

[[ "$file_path" == *"/obsidian-vault/"* ]] && exit 0

[[ "$file_path" == *"node_modules/"* ]] && exit 0
[[ "$file_path" == *".git/"* ]] && exit 0
[[ "$file_path" == *"__pycache__/"* ]] && exit 0

[ ! -f "$file_path" ] && exit 0

project="misc"
for path in "$cwd" "$file_path"; do
  if [[ "$path" == "$PROJECTS_ROOT/"* ]]; then
    relative="${path#$PROJECTS_ROOT/}"
    project="${relative%%/*}"
    break
  fi
done

week=$(cat "${VAULT}/current-week.txt" 2>/dev/null | tr -d '[:space:]')
today=$(date +%Y-%m-%d)
now=$(date +%H:%M)

[ -z "$week" ] && exit 0

target_dir="${VAULT}/Daily notes/week ${week}/${today}/claude/${project}"
mkdir -p "$target_dir"

basename=$(basename "$file_path")

[ -e "$target_dir/$basename" ] && exit 0

ln -s "$file_path" "$target_dir/$basename"

log_file="${VAULT}/Daily notes/week ${week}/${today}/claude-log_${project}_${today}.md"

if [ ! -f "$log_file" ]; then
  cat > "$log_file" <<FRONTMATTER
---
tags:
  - "#${project}"
daily-note: "[[${today}]]"
---

FRONTMATTER
fi

echo "- ${now} | Created [[claude/${project}/${basename}]] (from ${file_path})" >> "$log_file"
