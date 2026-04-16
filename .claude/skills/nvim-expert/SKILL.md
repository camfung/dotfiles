---
name: nvim-expert
description: "Subject matter expert for Neovim as used in this dotfiles project. Use when working with nvim config, understanding how nvim is set as EDITOR, or integrating nvim with shell tooling."
---

# Nvim Expert — dotfiles

## How This Project Uses Nvim

Nvim is the default editor. Set as `$EDITOR` in `zshrc` with SSH fallback to `vim`. Aliased as `v` in `aliases.zsh`. Binary installed at `/opt/nvim-linux-x86_64/bin/nvim` — added to PATH in `env.zsh`.

## Editor Config

Set in `zshrc`:

```zsh
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
```

Alias in `aliases.zsh`:
```zsh
alias v='nvim'
```

Mason (LSP/tool manager) bin directory added to PATH in `env.zsh`:
```zsh
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
```

## Nvim Binary Location

Installed manually to `/opt/nvim-linux-x86_64/` (not via package manager). PATH set in `env.zsh`:

```zsh
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
```

If `nvim` not found, verify `/opt/nvim-linux-x86_64/bin/nvim` exists. Download from [github.com/neovim/neovim/releases](https://github.com/neovim/neovim/releases) if missing.

## Nvim Config Location

Nvim config lives at `~/.config/nvim/` — this is **not tracked in this dotfiles repo**. The dotfiles repo only manages the shell integration (PATH, EDITOR, alias).

If you need to track nvim config, follow the existing pattern:
1. Add `config/nvim/` to dotfiles
2. Add symlink to `install.sh`: `ln -sf "$DOTFILES_DIR/config/nvim" ~/.config/nvim`

## Mason PATH

`~/.local/share/nvim/mason/bin` is in PATH (set in `env.zsh`). Tools installed via Mason (formatters, LSP servers, linters) are available in the shell. This is intentional — lets tools like `prettierd`, `black`, etc. run from terminal in addition to within nvim.

## Common Operations

### Open a file
```zsh
v path/to/file        # via alias
nvim path/to/file     # explicit
```

### Check which nvim is active
```zsh
which nvim
nvim --version
```

### Update nvim

Download new binary from GitHub releases, extract to `/opt/nvim-linux-x86_64/`:
```bash
# Extract to /opt, preserving the versioned directory name
tar -xzf nvim-linux-x86_64.tar.gz -C /opt/
# Then verify the path still matches env.zsh
ls /opt/nvim-linux-x86_64/bin/nvim
```

## Integration with Claude

`claude` CLI uses `$EDITOR` for file editing operations. With this config, Claude opens nvim for any editor invocations. The `EDITOR` guard ensures SSH sessions fall back to `vim` (which is more universally available).

## Gotchas

- Nvim binary is at `/opt/nvim-linux-x86_64/bin` — not `/usr/bin/nvim`. System package manager `nvim` may be a different (older) version.
- Mason bin path is prepended to PATH (`$HOME/.local/share/nvim/mason/bin:$PATH`) — Mason-installed tools take priority over system tools of the same name.
- Nvim config (`~/.config/nvim/`) is not in this dotfiles repo. It lives independently.
- `vim` fallback over SSH requires `vim` to be installed on remote machines separately.

## References

- [Neovim releases](https://github.com/neovim/neovim/releases)
- [Mason.nvim](https://github.com/williamboman/mason.nvim)
