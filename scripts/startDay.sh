#!/bin/bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set — add it to ~/.env.local}"

printf -v date '%(%Y-%m-%d)T' -1
mkdir "$date"

target_dir="${OBSIDIAN_VAULT}/Daily notes/week $1"

if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
fi

touch "$date/$date.md"

if [ "$(date +%u)" -eq 1 ]; then
  dateDiff=3
else
  dateDiff=1
fi

prevdate=$(date --date="$date -$dateDiff day" +%Y-%m-%d)

prevdatestr="\"[[Daily notes/week $1/$prevdate/$prevdate|$prevdate]]\""

declare -i currentDay=$(cat "${OBSIDIAN_VAULT}/current-day.txt")

echo "---
day: \"${currentDay}\"
week: \"$1\"
start time:
yesterday: $prevdatestr
tags:
  - \""#Week$1"\"
coffees drank:
claude-log: \"[[Daily notes/week $1/$date/claude-log_$date|claude-log]]\"
---" > "$date/$date.md"

echo $(( $currentDay + 1)) > "${OBSIDIAN_VAULT}/current-day.txt"
echo "$1" > "${OBSIDIAN_VAULT}/current-week.txt"

mv "$date" "$target_dir"
