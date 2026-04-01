obslink() {
  if [ $# -eq 0 ]; then
    echo "Usage: obslink <file_or_directory> [link_name]"
    echo "Creates a symbolic link from <file_or_directory> to ~/Documents/obsidian-vault/"
    echo "If link_name is not provided, uses the file/directory name"
    return 1
  fi

  local source_path="$1"
  local link_name="${2:-$(basename "$source_path")}"
  local target_dir="$HOME/Documents/obsidian-vault"

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

  ln "$abs_source_path" "$link_path"

  if [ $? -eq 0 ]; then
    echo "Successfully linked '$abs_source_path' to '$link_path'"
  else
    echo "Failed to create link"
    return 1
  fi
}
