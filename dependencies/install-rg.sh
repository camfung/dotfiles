#!/bin/bash
set -e

if command -v rg &>/dev/null; then
  echo "rg already installed: $(rg --version | head -n1)"
  exit 0
fi

if command -v apt-get &>/dev/null; then
  sudo apt-get update -qq && sudo apt-get install -y ripgrep
elif command -v brew &>/dev/null; then
  brew install ripgrep
elif command -v pacman &>/dev/null; then
  sudo pacman -S --noconfirm ripgrep
elif command -v dnf &>/dev/null; then
  sudo dnf install -y ripgrep
else
  echo "No supported package manager found for ripgrep"
  exit 1
fi

echo "rg installed: $(rg --version | head -n1)"
