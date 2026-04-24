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

# Ensure dotfiles-owned target dirs exist (safe to create on any machine).
mkdir -p ~/.claude/hooks ~/.local/bin

# Symlink scripts back to their expected locations
ln -sf "$DOTFILES_DIR/scripts/obsidian-symlink.sh" ~/.claude/hooks/obsidian-symlink.sh
echo "Linked obsidian-symlink.sh -> ~/.claude/hooks/"

# Obsidian vault is user data — only link if the vault is already present.
if [ -d ~/Documents/obsidian-vault ]; then
  ln -sf "$DOTFILES_DIR/scripts/startDay.sh" ~/Documents/obsidian-vault/startDay.sh
  echo "Linked startDay.sh -> ~/Documents/obsidian-vault/"
else
  echo "Skipped startDay.sh link (no ~/Documents/obsidian-vault on this machine)"
fi

ln -sf "$DOTFILES_DIR/scripts/rs-cli" ~/.local/bin/rs-cli
echo "Linked rs-cli -> ~/.local/bin/"

ln -sf "$DOTFILES_DIR/scripts/oracle-cli" ~/.local/bin/oracle-cli
echo "Linked oracle-cli -> ~/.local/bin/"

# Install kitty terminfo to ~/.terminfo so TERM=xterm-kitty resolves
# (ncurses auto-discovers ~/.terminfo; no sudo needed)
# Without this, Backspace and other keys can misbehave outside kitty's own session
# (especially over SSH when the remote host has no xterm-kitty entry).
KITTY_TERMINFO=""
for candidate in \
  "$HOME/.local/kitty.app/lib/kitty/terminfo/kitty.terminfo" \
  "/Applications/kitty.app/Contents/Resources/kitty/terminfo/kitty.terminfo" \
  "/usr/share/terminfo/kitty.terminfo"; do
  if [ -f "$candidate" ]; then
    KITTY_TERMINFO="$candidate"
    break
  fi
done
if command -v tic &>/dev/null && [ -n "$KITTY_TERMINFO" ] \
   && [ ! -f "$HOME/.terminfo/78/xterm-kitty" ] \
   && [ ! -f "$HOME/.terminfo/x/xterm-kitty" ]; then
  tic -x -o "$HOME/.terminfo" "$KITTY_TERMINFO" 2>/dev/null
  echo "Installed xterm-kitty terminfo -> ~/.terminfo/ (source: $KITTY_TERMINFO)"
fi

# Clone zsh-vi-mode OMZ custom plugin if not present
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-vi-mode" ]; then
  git clone https://github.com/jeffreytse/zsh-vi-mode \
    "$ZSH_CUSTOM_DIR/plugins/zsh-vi-mode"
  echo "Cloned zsh-vi-mode -> $ZSH_CUSTOM_DIR/plugins/"
else
  echo "zsh-vi-mode already cloned, skipping"
fi

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
