#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Backup existing zshrc
if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
  backup=~/.zshrc.bak.$(date +%Y%m%d%H%M%S)
  cp ~/.zshrc "$backup"
  echo "Backed up ~/.zshrc to $backup"
fi

# Symlink zshrc
ln -sf "$DOTFILES_DIR/zshrc" ~/.zshrc
echo "Linked ~/.zshrc -> $DOTFILES_DIR/zshrc"

# Make scripts executable
chmod +x "$DOTFILES_DIR/scripts/"*

# Symlink scripts back to their expected locations
ln -sf "$DOTFILES_DIR/scripts/obsidian-symlink.sh" ~/.claude/hooks/obsidian-symlink.sh
echo "Linked obsidian-symlink.sh -> ~/.claude/hooks/"

ln -sf "$DOTFILES_DIR/scripts/startDay.sh" ~/Documents/obsidian-vault/startDay.sh
echo "Linked startDay.sh -> ~/Documents/obsidian-vault/"

ln -sf "$DOTFILES_DIR/scripts/rs-cli" ~/.local/bin/rs-cli
echo "Linked rs-cli -> ~/.local/bin/"

ln -sf "$DOTFILES_DIR/scripts/oracle-cli" ~/.local/bin/oracle-cli
echo "Linked oracle-cli -> ~/.local/bin/"

# Copy env.local template if it doesn't exist
if [ ! -f ~/.env.local ]; then
  cp "$DOTFILES_DIR/env.local.example" ~/.env.local
  echo "Created ~/.env.local from template — edit it with your machine's paths"
else
  echo "~/.env.local already exists, skipping"
fi

# Copy machine-local template if it doesn't exist
if [ ! -f ~/.machine-local.zsh ]; then
  cp "$DOTFILES_DIR/machine-local.zsh.example" ~/.machine-local.zsh
  echo "Created ~/.machine-local.zsh from template — add machine-specific config"
else
  echo "~/.machine-local.zsh already exists, skipping"
fi

echo ""
echo "Done! Run 'source ~/.zshrc' to reload."
