#!/bin/bash
set -e

DEPS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dependencies from $DEPS_DIR"

failed=()
for script in "$DEPS_DIR"/install-*.sh; do
  name=$(basename "$script")
  [ "$name" = "install-all.sh" ] && continue
  echo ""
  echo "==> $name"
  if ! bash "$script"; then
    failed+=("$name")
  fi
done

echo ""
if [ ${#failed[@]} -eq 0 ]; then
  echo "All dependencies installed."
else
  echo "Failed: ${failed[*]}"
  exit 1
fi
