#!/bin/bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set — add it to ~/.env.local}"

printf -v date '%(%Y-%m-%d)T' -1
mkdir "$date"

week=$1

if [ -z $week ] ; then
  week=$(cat "${OBSIDIAN_VAULT}/current-week.txt")
  prevweek=$week
fi

if [ "$(date +%u)" -eq 1 ]; then
  dateDiff=3
  week=$((week + 1))
  echo $week > "${OBSIDIAN_VAULT}/current-week.txt"
else
  dateDiff=1
fi


target_dir="${OBSIDIAN_VAULT}/Daily notes/week ${week}"

if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
fi

touch "$date/$date.md"


prevdate=$(date --date="$date -$dateDiff day" +%Y-%m-%d)

prevdatestr="\"[[Daily notes/week ${prevweek}/$prevdate/$prevdate|$prevdate]]\""

declare -i currentDay=$(cat "${OBSIDIAN_VAULT}/current-day.txt")

echo "---
day: \"${currentDay}\"
week: \"$week\"
start time:
home time:
yesterday: $prevdatestr
tags:
  - \""#Week$week"\"
coffees drank:
---" > "$date/$date.md"

echo $(( $currentDay + 1)) > "${OBSIDIAN_VAULT}/current-day.txt"

mv "$date" "$target_dir"
