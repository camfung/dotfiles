m3get() {
  if [ $# -eq 0 ]; then
    echo "Usage: m3get <remote_path> [local_subdir]"
    echo "  scp from ${M3_HOST:-100.107.4.82}:<remote_path> to ~/m3[/<local_subdir>]/"
    echo "  Override host/user with M3_HOST / M3_USER env vars."
    return 1
  fi

  local remote_host="${M3_HOST:-100.107.4.82}"
  local remote_user="camer"
  local remote_path="$1"
  local subdir="${2:-}"
  local dest_dir="${HOME}/m3"

  if [ -n "$subdir" ]; then
    dest_dir="${HOME}/m3/${subdir#/}"
  fi

  mkdir -p "$dest_dir" || {
    echo "Error: failed to create '$dest_dir'"
    return 1
  }

  scp -r "${remote_user}@${remote_host}:${remote_path}" "${dest_dir}/"
}
