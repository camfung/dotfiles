---
tags:
  - dotfiles
  - zsh
  - vi-mode
  - setup
---

# zsh-vi-mode Setup

This document records how `jeffreytse/zsh-vi-mode` is wired into this dotfiles repo: install steps, where files land on disk, and the versions that were in use when the integration was committed.

## What it replaces

Before this change, vi-mode in the shell was provided by a bare `set -o vi` plus two custom `bindkey` calls in `zshrc` that mapped `Y` to a clipboard-yank widget. That worked but missed surround text objects, visual-mode highlighting, cursor-shape per mode, and the system yank/put integration that `zsh-vi-mode` provides.

The plugin loads through Oh My Zsh's custom-plugin mechanism rather than through a second plugin manager (e.g., zinit), which keeps the config to a single plugin manager.

## Install steps

The installer (`install.sh`) is idempotent — re-running it on a fresh machine does everything below.

1. Ensure Oh My Zsh is installed (`~/.oh-my-zsh` must exist). This repo assumes OMZ is already bootstrapped; it is not cloned by `install.sh`.
2. From the repo root, run:
   ```bash
   bash ~/dotfiles/install.sh
   ```
   The relevant block clones the plugin only when missing:
   ```bash
   ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
   if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-vi-mode" ]; then
     git clone https://github.com/jeffreytse/zsh-vi-mode \
       "$ZSH_CUSTOM_DIR/plugins/zsh-vi-mode"
   fi
   ```
3. Reload the shell:
   ```bash
   exec zsh
   ```
4. Verify the plugin is active: press `Esc` at a prompt and the cursor should change shape (block in normal mode, beam in insert mode).
5. Verify the preserved `Y` clipboard-yank binding: type a line, `Esc`, `Y`, then `xclip -selection clipboard -o` should echo the yanked line.

## Install locations

| Component | Path |
|-----------|------|
| Dotfiles repo | `~/dotfiles` |
| Symlinked shell rc | `~/.zshrc` → `~/dotfiles/zshrc` |
| Oh My Zsh | `~/.oh-my-zsh` |
| OMZ custom plugin dir | `~/.oh-my-zsh/custom/plugins` |
| `zsh-vi-mode` clone | `~/.oh-my-zsh/custom/plugins/zsh-vi-mode` |
| Plugin source | `~/.oh-my-zsh/custom/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh` |

`$ZSH_CUSTOM` defaults to `$ZSH/custom` (i.e. `~/.oh-my-zsh/custom`). The installer respects an override if one is exported.

## Configuration points in `zshrc`

Three related blocks in `~/dotfiles/zshrc`:

1. **Plugin list** — `plugins=(z zsh-vi-mode)`. Order matters only when plugins bind overlapping keys; here it does not.
2. **Editor block** — `EDITOR` is set to `nvim` when available, falling back to `vim`. `VISUAL=$EDITOR` so `v` in vicmd (the plugin's "edit current command in editor" binding) opens nvim.
3. **Y binding hook** — the `zle-clipboard-yank` widget is defined at top level, but its `bindkey` calls live inside `zvm_after_lazy_keybindings()`. This is required because zsh-vi-mode rebuilds the `vicmd` and `visual` keymaps during lazy init, which would otherwise clobber any bindings set earlier in `zshrc`.

`set -o vi` was removed — the plugin runs `bindkey -v` itself.

## Customizing further

zsh-vi-mode has no config file. All configuration uses either environment variables (set before the plugin loads) or lifecycle-hook functions (defined anywhere in `zshrc`). Common knobs:

- `ZVM_INIT_MODE=sourcing` — disable lazy init if bindings feel wrong on first keystroke.
- `ZVM_VI_HIGHLIGHT_BACKGROUND=#3a3a3a` — visual-mode highlight color.
- `ZVM_CURSOR_STYLE_ENABLED=true` — per-mode cursor shape (default true).
- `ZVM_VI_SURROUND_BINDKEY=classic` — surround.vim-style bindings.
- Hook functions: `zvm_config`, `zvm_before_init`, `zvm_after_init`, `zvm_after_lazy_keybindings`, `zvm_after_select_vi_mode`.

Full reference: <https://github.com/jeffreytse/zsh-vi-mode#-configuration>.

## Versions at time of integration

Recorded 2026-04-21 on the integrator's machine. These are the exact versions the setup was tested against; newer versions of each component are expected to work.

| Component | Version |
|-----------|---------|
| zsh | 5.9 (x86_64-ubuntu-linux-gnu) |
| Neovim | v0.11.6 |
| xclip | 0.13 |
| Oh My Zsh | HEAD `061f773` (`ci: use client-id rather than app-id (#13690)`) |
| jeffreytse/zsh-vi-mode | v0.12.0 + 7 commits — HEAD `08bd1c0` (`docs: remove Fig instructions (#336)`) |
| OS | Linux 6.17.0-20-generic (Ubuntu-family) |

To re-check these locally:

```bash
zsh --version
nvim --version | head -1
xclip -version 2>&1 | head -1
git -C ~/.oh-my-zsh log -1 --format='%h %s'
git -C ~/.oh-my-zsh/custom/plugins/zsh-vi-mode describe --tags --always
```

## Uninstall

1. Remove `zsh-vi-mode` from the `plugins=(...)` array in `zshrc`.
2. Restore `set -o vi` and the top-level `bindkey` lines for `Y` (see git history prior to commit `8ab3e99` for the original block).
3. Delete the clone:
   ```bash
   rm -rf ~/.oh-my-zsh/custom/plugins/zsh-vi-mode
   ```
4. Reload: `exec zsh`.
