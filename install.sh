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

# Claude Code statusline (referenced by ~/.claude/settings.json statusLine.command)
ln -sf "$DOTFILES_DIR/scripts/statusline.sh" ~/.claude/statusline.sh
echo "Linked statusline.sh -> ~/.claude/"

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

mkdir -p ~/.config/kitty
ln -sf "$DOTFILES_DIR/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES_DIR/config/kitty/tab_bar.py" ~/.config/kitty/tab_bar.py
echo "Linked kitty config -> ~/.config/kitty/"

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

# Load GNOME Vitals extension config (CPU usage/temp + memory in top bar).
# Only on GNOME with dconf available; harmless to skip elsewhere.
if command -v dconf &>/dev/null && [ -f "$DOTFILES_DIR/config/gnome/vitals.dconf" ]; then
  dconf load /org/gnome/shell/extensions/vitals/ < "$DOTFILES_DIR/config/gnome/vitals.dconf"
  echo "Loaded GNOME Vitals config -> dconf"
  if command -v gnome-extensions &>/dev/null; then
    gnome-extensions enable Vitals@CoreCoding.com 2>/dev/null \
      && echo "Enabled Vitals extension" \
      || echo "Vitals extension not installed — get it from extensions.gnome.org"
  fi
fi

# Fixed 5 GNOME workspaces switched with Super+1..5 (virtual desktops).
# Disables dynamic workspaces, pins the count at 5, frees Super+1..5 from the
# dash app-switcher, and rebinds them to workspace switching. GNOME-only.
if command -v gsettings &>/dev/null && gsettings list-schemas 2>/dev/null | grep -q '^org.gnome.mutter$'; then
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
  for i in 1 2 3 4 5; do
    gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
    gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
  done
  # Ubuntu's Dash-to-Dock also binds Super+number to dock apps — disable so it
  # doesn't shadow workspace switching.
  if gsettings list-schemas 2>/dev/null | grep -q '^org.gnome.shell.extensions.dash-to-dock$'; then
    gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false
  fi
  echo "Configured 5 GNOME workspaces (Super+1..5 to switch)"
fi

# LAN Port Index — service-discovery start page on :8888 (systemd --user service).
mkdir -p ~/.local/bin ~/.config/systemd/user ~/.config/lanindex
ln -sf "$DOTFILES_DIR/scripts/lanindex.py" ~/.local/bin/lanindex
ln -sf "$DOTFILES_DIR/config/systemd/lanindex.service" ~/.config/systemd/user/lanindex.service
echo "Linked lanindex -> ~/.local/bin/ and lanindex.service -> ~/.config/systemd/user/"
if [ ! -f ~/.config/lanindex/registry.toml ]; then
  cp "$DOTFILES_DIR/config/lanindex/registry.example.toml" ~/.config/lanindex/registry.toml
  echo "Seeded ~/.config/lanindex/registry.toml"
fi
# Desktop launcher — opens the dashboard in an app-mode browser window.
ln -sf "$DOTFILES_DIR/scripts/lanindex-open" ~/.local/bin/lanindex-open
mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/scalable/apps
ln -sf "$DOTFILES_DIR/config/lanindex/lanindex.desktop" ~/.local/share/applications/lanindex.desktop
ln -sf "$DOTFILES_DIR/config/lanindex/lanindex.svg" ~/.local/share/icons/hicolor/scalable/apps/lanindex.svg
command -v update-desktop-database &>/dev/null && update-desktop-database ~/.local/share/applications 2>/dev/null || true
echo "Installed LAN Port Index desktop app"

if command -v systemctl &>/dev/null; then
  systemctl --user daemon-reload
  systemctl --user enable --now lanindex.service 2>/dev/null \
    && echo "LAN Port Index running on :8888" \
    || echo "Enable manually: systemctl --user enable --now lanindex.service"
fi

# Network HTML Host — OPTIONAL. Always-on host for self-contained HTML docs (:8989).
# Opt in with:  INSTALL_HTML_HOST=1 ./install.sh
if [ "${INSTALL_HTML_HOST:-0}" = "1" ]; then
  HTML_HOST_SRC="${HTML_HOST_SRC:-$HOME/.local/share/network-html-host}"
  if [ -d "$HTML_HOST_SRC/.git" ]; then
    git -C "$HTML_HOST_SRC" pull --ff-only --quiet && echo "Updated network-html-host"
  else
    git clone --quiet https://github.com/camfung/network-html-host "$HTML_HOST_SRC" \
      && echo "Cloned network-html-host -> $HTML_HOST_SRC"
  fi
  bash "$HTML_HOST_SRC/install.sh"
else
  echo "Skipped Network HTML Host (set INSTALL_HTML_HOST=1 to install)"
fi

echo ""
echo "Installing core dependencies (fd, rg, claude)..."
bash "$DOTFILES_DIR/dependencies/install-all.sh"

echo ""
echo "Done! Run 'source ~/.zshrc' to reload."
