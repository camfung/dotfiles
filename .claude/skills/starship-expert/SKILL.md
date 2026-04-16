---
name: starship-expert
description: "Subject matter expert for Starship prompt as used in this dotfiles project. Use when editing config/starship.toml, changing prompt layout, adding/removing modules, or debugging prompt display."
---

# Starship Expert — dotfiles

## How This Project Uses Starship

Starship replaces oh-my-zsh themes (`ZSH_THEME=""`). Initialized conditionally in `zshrc`:

```zsh
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
```

Config lives at `~/dotfiles/config/starship.toml`. Starship reads it from `~/.config/starship.toml` — **install.sh does not currently symlink this file**. Must be symlinked or copied manually (or add to install.sh).

## Current Config — `dotfiles/config/starship.toml`

### Prompt Layout

Two-line prompt (newline in format string):

```
{directory}
{time}{git_branch}{git_status}{python}{cmd_duration}{character}
```

`add_newline = false` — no blank line between prompts.

### Active Modules

| Module | Format | Notes |
|---|---|---|
| `directory` | `[$path]($style)` | Full path, no truncation (`truncation_length = 0`, `truncate_to_repo = false`) |
| `time` | `[$time]($style) ` — `%H:%M:%S` | Always shown |
| `git_branch` | `[$branch]($style) ` | Branch name only |
| `git_status` | `[$all_status$ahead_behind]($style) ` | All status indicators |
| `python` | `[${virtualenv}]($style) ` | Virtualenv name only; **no auto-detect** (all detect_* = []) |
| `cmd_duration` | `[$duration]($style) ` — `min_time = 0`, `show_milliseconds = true` | Always shown, includes ms |
| `character` | `❯` green/red | Success/error indicator |

### Python Module Detail

`detect_extensions`, `detect_files`, `detect_folders` are all `[]` — python module only shows when a virtualenv is **active**, not when Python files are present. This prevents the module from appearing in every directory.

## Common Operations

### Change prompt order

Edit the `format` string in `starship.toml`. Modules listed = modules shown:

```toml
format = """
$directory
$time$git_branch$git_status$python$cmd_duration$character"""
```

### Add a new module

Add the module config block and include `$module_name` in the `format` string.

Example — add Node.js version:
```toml
# In format string:
format = """
$directory
$time$git_branch$git_status$nodejs$python$cmd_duration$character"""

# Module config:
[nodejs]
format = "[$version]($style) "
```

### Disable a module

Remove it from `format` string OR add `disabled = true`:

```toml
[time]
disabled = true
```

### Test config changes

```bash
starship explain        # show which modules are active and why
starship print-config   # show resolved config
source ~/.zshrc         # reload prompt
```

## Symlinking the Config

Starship reads from `~/.config/starship.toml`. To wire it up:

```bash
mkdir -p ~/.config
ln -sf ~/dotfiles/config/starship.toml ~/.config/starship.toml
```

This is not in `install.sh` yet — add it there if needed.

## Gotchas

- `ZSH_THEME=""` in `zshrc` is required — setting any oh-my-zsh theme conflicts with Starship.
- Starship init only runs if `starship` is in PATH (`command -v` guard). If prompt is plain, check `which starship`.
- `cmd_duration` with `min_time = 0` shows duration for every command including instant ones. Increase `min_time` (ms) if this is noisy.
- Python virtualenv shows only when `$VIRTUAL_ENV` is set (activated) — no directory-based detection by design.
- `truncate_to_repo = false` means full absolute path shown — can be long in deep dirs. Increase `truncation_length` to limit.

## References

- [Starship docs](https://starship.rs/config/)
- [Starship module reference](https://starship.rs/config/#prompt)
