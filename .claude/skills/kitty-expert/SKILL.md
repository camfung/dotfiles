---
name: kitty-expert
description: "Subject matter expert for Kitty terminal as used in this dotfiles project. Use when adding kitty config, editing keybindings, fonts, or colors. Config location and install.sh wiring not yet committed."
---

# Kitty Expert — dotfiles

## How This Project Uses Kitty

Kitty is the primary terminal emulator on this Linux machine. Config directory is `~/dotfiles/config/kitty/` — referenced in codebase context but the directory is currently empty (no `.conf` files committed yet). Starship handles the prompt inside Kitty.

## Config Location

Kitty reads from `~/.config/kitty/kitty.conf`. The dotfiles convention is to keep configs under `~/dotfiles/config/<tool>/` and symlink:

```bash
mkdir -p ~/.config/kitty
ln -sf ~/dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

Add this symlink to `install.sh` when the config is created (follow the `ln -sf "$DOTFILES_DIR/..."` pattern already used for other files).

## Adding a Kitty Config

Create `~/dotfiles/config/kitty/kitty.conf`:

```conf
# Font
font_family      JetBrainsMono Nerd Font
font_size        13.0

# Tab bar
tab_bar_style    powerline

# Colors — example (replace with actual theme)
background       #1e1e2e
foreground       #cdd6f4
```

Then symlink via install.sh or manually:
```bash
ln -sf ~/dotfiles/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

## Common Operations

### Reload config without restarting

`Ctrl+Shift+F5` (default) or:
```bash
kill -SIGUSR1 $(pgrep kitty)
```

### Adding keybindings

```conf
# In kitty.conf
map ctrl+shift+t new_tab_with_cwd
map ctrl+shift+enter new_window_with_cwd
```

### Remote control (scripting kitty)

```conf
# Enable in kitty.conf
allow_remote_control yes
```

Then use `kitty @ ...` commands from the shell.

## Integration with Starship

Kitty renders Starship's prompt. If prompt icons/symbols appear broken, install a Nerd Font and set it as `font_family` in kitty.conf. The starship config uses `❯` (U+276F) which renders in any font.

## install.sh Wiring (when config is ready)

Add to `install.sh` after the existing symlink block:

```bash
mkdir -p ~/.config/kitty
ln -sf "$DOTFILES_DIR/config/kitty/kitty.conf" ~/.config/kitty/kitty.conf
echo "Linked kitty.conf -> ~/.config/kitty/"
```

## Gotchas

- `~/dotfiles/config/kitty/` directory is in the codebase context but currently empty — no `.conf` committed yet.
- Kitty uses `~/.config/kitty/kitty.conf` by default. `$KITTY_CONFIG_DIRECTORY` env var overrides this.
- Config changes take effect on reload (`Ctrl+Shift+F5`), not on new terminal open.
- Kitty does not source `~/.zshrc` on startup unless configured — it uses the shell binary set in `shell` config option (defaults to system default shell).

## References

- [Kitty config docs](https://sw.kovidgoyal.net/kitty/conf/)
- [Kitty keybindings reference](https://sw.kovidgoyal.net/kitty/actions/)
