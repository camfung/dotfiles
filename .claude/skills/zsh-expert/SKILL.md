---
name: zsh-expert
description: "Subject matter expert for Zsh as used in this dotfiles project. Use when editing zshrc, aliases.zsh, env.zsh, functions/*.zsh, or adding new shell config, aliases, keybindings, or conditional tool loading."
---

# Zsh Expert — dotfiles

## How This Project Uses Zsh

Zsh with oh-my-zsh (z plugin only, no theme — Starship handles prompt). Entry point is `~/dotfiles/zshrc` symlinked to `~/.zshrc` by `install.sh`. Config is split across modular files sourced at startup.

## Load Order

```
zshrc
  ├── exports PATH
  ├── oh-my-zsh (plugins=(z))
  ├── EDITOR (nvim unless SSH)
  ├── vi mode + ZLE keybindings
  ├── source ~/dotfiles/env.zsh
  ├── source ~/dotfiles/aliases.zsh
  ├── for f in ~/dotfiles/functions/*.zsh; do source "$f"; done
  ├── [[ -f ~/.env.local ]] && source ~/.env.local
  ├── conditional tool blocks (eza, starship, copyq, fdfind, nvm, flatpak, docker, xmodmap, rs-cli, oracle-cli)
  └── [[ -f ~/.machine-local.zsh ]] && source ~/.machine-local.zsh
```

## File Responsibilities

| File | Purpose |
|---|---|
| `~/dotfiles/zshrc` | Entry point, oh-my-zsh init, vi mode, ZLE, conditional tool loading |
| `~/dotfiles/env.zsh` | PATH additions, env var exports (JAVA_HOME, CLAUDE_PLUGIN_DATA, etc.) |
| `~/dotfiles/aliases.zsh` | All persistent aliases (git, nav, editor, python, claude, misc) |
| `~/dotfiles/functions/*.zsh` | Shell functions, one topic per file, auto-sourced |
| `~/.env.local` | Per-machine env vars (not tracked; template: `env.local.example`) |
| `~/.machine-local.zsh` | Per-machine aliases/config (not tracked; template: `machine-local.zsh.example`) |

## Common Operations

### Adding a new alias

Add to `~/dotfiles/aliases.zsh`. No section headers required — just group logically with a comment.

```zsh
# My tool
alias mt='my-tool --flag'
```

If alias depends on tool availability, add a conditional block in `zshrc` instead:

```zsh
if command -v mytool &>/dev/null; then
  alias mt='mytool --flag'
fi
```

### Adding a new shell function

Create `~/dotfiles/functions/<name>.zsh`. It is auto-sourced on next shell start. Function name does not need to match filename but conventionally does.

```zsh
# ~/dotfiles/functions/myfunc.zsh
myfunc() {
  # implementation
}
```

### Adding a new PATH or env var

Add to `~/dotfiles/env.zsh`:

```zsh
export PATH="$PATH:/opt/mytool/bin"
export MY_VAR="value"
```

For machine-specific values, add to `~/.env.local` (not tracked). The template is `~/dotfiles/env.local.example`.

### Adding a ZLE keybinding

Add to `zshrc` after `set -o vi`. Follow the existing pattern:

```zsh
function zle-my-widget {
  zle some-zle-action
  # additional logic
}
zle -N zle-my-widget
bindkey -M vicmd 'KEY' zle-my-widget
```

Existing example: `Y` in vicmd/visual yanks to X clipboard via `xclip`.

### Reloading config

```zsh
source ~/.zshrc
```

### Adding machine-specific config

Edit `~/.machine-local.zsh` (not tracked). Template at `~/dotfiles/machine-local.zsh.example`. Sourced last — overrides anything set earlier.

## Conditional Tool Loading Pattern

All optional tools use this guard:

```zsh
if command -v TOOL &>/dev/null; then
  alias x='TOOL ...'
fi
```

Single-line shorthand for alias-only:

```zsh
command -v TOOL &>/dev/null && alias x='TOOL'
```

Never assume a tool is installed. Every tool-dependent alias/config in `zshrc` already follows this pattern.

## Oh-My-Zsh Usage

- `ZSH_THEME=""` — theme disabled, Starship handles prompt
- `plugins=(z)` — only z (directory jumping) is loaded
- Do not add heavyweight plugins; keep startup fast

## Vi Mode & ZLE

- `set -o vi` enables vi keybindings globally
- Custom widget `zle-clipboard-yank` syncs vi yank buffer to X clipboard (`xclip`)
- Bound to `Y` in both `vicmd` and `visual` maps

## Key Env Vars Set Here

| Var | Value | Set in |
|---|---|---|
| `EDITOR` | `nvim` (or `vim` over SSH) | `zshrc` |
| `JAVA_HOME` | `/usr/lib/jvm/java-21-openjdk-amd64` | `zshrc` (bottom) |
| `ANDROID_HOME` | `~/Android/Sdk` | `zshrc` (bottom) |
| `NVM_DIR` | `$HOME/.nvm` | `zshrc` |
| `CLAUDE_PLUGIN_DATA` | `/home/camer/.claude/plugins/data/shipyard-acendas` | `env.zsh` |
| `FD_OPTIONS` | `--unrestricted --full-path` | `zshrc` (conditional) |
| `OBSIDIAN_VAULT` | set in `~/.env.local` | `env.local.example` |
| `PROJECTS_ROOT` | set in `~/.env.local` | `env.local.example` |

## Gotchas

- `~/.env.local` must exist for `OBSIDIAN_VAULT`-dependent scripts (`startDay.sh`, `obsidian-symlink.sh`) to work. `install.sh` creates it from template if missing.
- `~/.machine-local.zsh` sourced last — good place to override anything. Not tracked.
- Adding a new `functions/*.zsh` file takes effect on next `source ~/.zshrc` or new shell — the glob expansion happens at source time.
- `ZSH_THEME=""` is intentional — do not set a theme or it will conflict with Starship.
- `nvm` loading is unconditional (checks for file existence, not command) — keep it that way for nvm compatibility.
- `env.zsh` PATH for nvim: `/opt/nvim-linux-x86_64/bin` — if nvim not found, check this path exists.

## References

- [Oh My Zsh docs](https://ohmyz.sh/)
- [zle(1) man page](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html)
- [z plugin](https://github.com/agkozak/zsh-z)
