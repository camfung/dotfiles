obslink() {
  local move=0
  while [[ "$1" == -* ]]; do
    case "$1" in
      -m|--move) move=1; shift ;;
      *) echo "Unknown option: $1"; return 1 ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo "Usage: obslink [-m|--move] <file_or_directory> [link_name]"
    echo "Creates a symbolic link from <file_or_directory> to ~/Documents/obsidian-vault/"
    echo "With -m|--move, moves the file instead of linking it"
    echo "If link_name is not provided, uses the file/directory name"
    return 1
  fi

  local source_path="$1"
  local date=${(%):-%D{%Y-%m-%d}}
  local current_week=$(<"${OBSIDIAN_VAULT}/current-week.txt")
  local target_dir="${OBSIDIAN_VAULT}/Daily notes/week ${current_week}/${date}"
  local link_name="${2:-${source_path:t}}"

  if [ ! -e "$source_path" ]; then
    echo "Error: File or directory '$source_path' does not exist"
    return 1
  fi

  mkdir -p "$target_dir"

  local abs_source_path="$(realpath "$source_path")"
  local link_path="$target_dir/$link_name"

  if [ -L "$link_path" ] || [ -e "$link_path" ]; then
    echo "Warning: '$link_path' already exists"
    read -q "REPLY?Do you want to overwrite it? (y/n) "
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted"
      return 1
    fi
    rm -rf "$link_path"
  fi

  if [ "$move" -eq 1 ]; then
    mv "$abs_source_path" "$link_path"
  else
    ln "$abs_source_path" "$link_path"
  fi

  if [ $? -eq 0 ]; then
    if [ "$move" -eq 1 ]; then
      echo "Successfully moved '$abs_source_path' to '$link_path'"
    else
      echo "Successfully linked '$abs_source_path' to '$link_path'"
    fi
  else
    if [ "$move" -eq 1 ]; then
      echo "Failed to move"
    else
      echo "Failed to create link"
    fi
    return 1
  fi
}
