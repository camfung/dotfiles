#!/bin/bash
set -e

if command -v fd &>/dev/null; then
  echo "fd already installed: $(fd --version)"
  exit 0
fi

if command -v apt-get &>/dev/null; then
  # Debian/Ubuntu ships fd as `fd-find` with binary `fdfind` to avoid name clash.
  # Install package, then symlink to `fd` in ~/.local/bin (already on PATH via env.zsh).
  sudo apt-get update -qq && sudo apt-get install -y fd-find
  mkdir -p ~/.local/bin
  ln -sf "$(command -v fdfind)" ~/.local/bin/fd
  echo "Linked fdfind -> ~/.local/bin/fd"
elif command -v brew &>/dev/null; then
  brew install fd
elif command -v pacman &>/dev/null; then
  sudo pacman -S --noconfirm fd
elif command -v dnf &>/dev/null; then
  sudo dnf install -y fd-find
else
  echo "No supported package manager found for fd"
  exit 1
fi

echo "fd installed: $(fd --version)"
