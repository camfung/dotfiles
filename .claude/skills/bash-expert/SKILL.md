---
name: bash-expert
description: "Subject matter expert for Bash scripting as used in this dotfiles project. Use when editing install.sh, scripts/*.sh, or the obsidian-symlink.sh PostToolUse hook. Covers script conventions, install patterns, and Claude hook integration."
---

# Bash Expert — dotfiles

## How This Project Uses Bash

Bash for all scripts in `dotfiles/scripts/` and `install.sh`. Scripts are NOT sourced into the shell — they run as subprocesses. `install.sh` is the single bootstrap. `obsidian-symlink.sh` doubles as both a Claude PostToolUse hook (reads JSON from stdin) and a standalone CLI.

## Scripts Inventory

| Script | Location | Purpose |
|---|---|---|
| `install.sh` | `dotfiles/install.sh` | Bootstrap: symlink dotfiles, create local config templates |
| `obsidian-symlink.sh` | `dotfiles/scripts/obsidian-symlink.sh` | Claude PostToolUse hook + manual `olink` alias |
| `startDay.sh` | `dotfiles/scripts/startDay.sh` | Create Obsidian daily note with YAML frontmatter |
| `rs-cli` | `dotfiles/scripts/rs-cli` | Custom CLI (symlinked to `~/.local/bin/rs-cli`) |
| `oracle-cli` | `dotfiles/scripts/oracle-cli` | Custom CLI (symlinked to `~/.local/bin/oracle-cli`) |

## install.sh Conventions

- `set -e` at top — any error aborts
- Resolves `DOTFILES_DIR` with `cd "$(dirname "$0")" && pwd` — works from any cwd
- Uses `ln -sf` (force symlink, replaces existing)
- Backs up existing `~/.zshrc` before replacing it (timestamped `.bak`)
- For untracked config files (`~/.env.local`, `~/.machine-local.zsh`): copies template only if target doesn't exist — never overwrites user edits

### Adding a new symlink to install.sh

```bash
ln -sf "$DOTFILES_DIR/scripts/myscript.sh" ~/.target/location
echo "Linked myscript.sh -> ~/.target/location"
chmod +x "$DOTFILES_DIR/scripts/myscript.sh"
```

Scripts are made executable in bulk (`chmod +x "$DOTFILES_DIR/scripts/"*`) — new scripts get executable perms automatically.

## obsidian-symlink.sh (PostToolUse Hook)

Reads JSON from stdin (Claude hook protocol). Key fields extracted with `jq`:

```bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')
```

**What it does:**
1. Reads `$OBSIDIAN_VAULT/current-week.txt` for week number
2. Derives project name from `$PROJECTS_ROOT/<project>/...` path pattern
3. Skips: files inside `obsidian-vault/`, `node_modules/`, `.git/`, `__pycache__/`
4. Creates symlink at `Daily notes/week {W}/{DATE}/claude/{project}/{module}/`
5. Module = first non-noise subdir (noise = `src|lib|main|java|com|org|kotlin|scala|resources|app|pkg|internal|cmd`)

**Required env vars** (set in `~/.env.local`):
- `OBSIDIAN_VAULT` — path to vault (defaults to `$HOME/Documents/obsidian-vault`)
- `PROJECTS_ROOT` — projects root (defaults to `$HOME/Documents/Projects`)

**Exits silently** (exit 0) when conditions not met — correct hook behavior, never errors Claude.

The script is symlinked to `~/.claude/hooks/obsidian-symlink.sh` by `install.sh`. Also accessible as `olink` alias from `aliases.zsh`.

## startDay.sh Conventions

- Uses `": ${VAR:?message}"` for required var validation — fails with message if unset
- `printf -v date '%(%Y-%m-%d)T' -1` — bash builtin date formatting (no `date` fork)
- Creates `$OBSIDIAN_VAULT/Daily notes/week $1/$date/$date.md` with YAML frontmatter
- Increments `$OBSIDIAN_VAULT/current-day.txt`
- Writes week number to `$OBSIDIAN_VAULT/current-week.txt` (used by `obsidian-symlink.sh`)
- Takes week number as `$1` argument: `startday 17`

## Common Script Patterns

### Required env var validation
```bash
: "${OBSIDIAN_VAULT:?OBSIDIAN_VAULT not set — add it to ~/.env.local}"
```

### Resolve script directory (portable)
```bash
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
```

### Guard before creating symlink
```bash
[ -e "$target" ] && exit 0   # skip if already exists
ln -s "$source" "$target"
```

### Skip paths matching patterns
```bash
[[ "$file_path" == *"/obsidian-vault/"* ]] && exit 0
[[ "$file_path" == *"node_modules/"* ]] && exit 0
```

## Testing Scripts

No test framework. Test manually:

```bash
# Test install.sh (dry run — inspect, don't run destructively)
bash -n install.sh          # syntax check

# Test obsidian-symlink.sh manually
echo '{"tool_input":{"file_path":"/path/to/file"},"cwd":"/path"}' | bash scripts/obsidian-symlink.sh

# Test startDay.sh
OBSIDIAN_VAULT=~/Documents/obsidian-vault bash scripts/startDay.sh 17
```

## Gotchas

- `obsidian-symlink.sh` exits 0 silently in all skip cases — this is intentional for Claude hook protocol. Do not add error exits for normal skip conditions.
- `install.sh` uses `set -e` — any failed command aborts the whole install. Wrap optional steps in `|| true` if they can fail non-fatally.
- `startDay.sh` must be run from a directory where it can create a `$date/` subdirectory — it runs `mkdir "$date"` in cwd. The `startday` alias runs it directly; be aware of cwd.
- Scripts are made executable by `install.sh` via `chmod +x scripts/*` — new scripts in `scripts/` get this automatically on next install.
- `jq` is a hard dependency of `obsidian-symlink.sh` — must be installed on the machine.

## References

- [Bash manual](https://www.gnu.org/software/bash/manual/)
- [Claude hooks protocol](https://docs.anthropic.com/en/docs/claude-code/hooks)
