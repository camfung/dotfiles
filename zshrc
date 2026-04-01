export PATH=$HOME/bin:$HOME/.local/bin:$PATH

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(z)
source $ZSH/oh-my-zsh.sh

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

set -o vi

# Load dotfiles modules
source ~/dotfiles/env.zsh
source ~/dotfiles/aliases.zsh
for f in ~/dotfiles/functions/*.zsh; do source "$f"; done

# Load env.local for script config (paths, etc.)
[[ -f ~/.env.local ]] && source ~/.env.local

# --- Conditional tool loading ---

# eza
if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -lah --icons'
fi

# starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# copyq
if command -v copyq &>/dev/null; then
  alias ic="copyq copy - > /dev/null"
  alias cqp='copyq read 0'
fi

# fdfind
if command -v fdfind &>/dev/null; then
  alias fd="fdfind"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# flatpak obsidian
if command -v flatpak &>/dev/null; then
  alias obs="flatpak run md.obsidian.Obsidian"
fi

# docker-dependent aliases
if command -v docker &>/dev/null; then
  alias structurizr='docker run -it --rm -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite'
fi

# xmodmap (colemak/qwerty)
if command -v xmodmap &>/dev/null; then
  alias colemak='setxkbmap us; xmodmap ~/colemak-1.0/xmodmap/xmodmap.colemak && xset r 66'
  alias qwerty='setxkbmap us; xset -r 66'
fi

# rs-cli / oracle-cli
command -v rs-cli &>/dev/null && alias rs='rs-cli'
command -v oracle-cli &>/dev/null && alias ora='oracle-cli'

# Load local bin env helper
. "$HOME/.local/bin/env" 2>/dev/null

# Machine-specific config (not tracked)
[[ -f ~/.machine-local.zsh ]] && source ~/.machine-local.zsh
