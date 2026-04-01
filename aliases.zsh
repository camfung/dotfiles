# Git
alias gs='git status'
alias gp='git push'
alias gc='git commit -m'
alias gl='git log --oneline --graph --decorate'
alias ga='git add'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'

# Navigation
alias c='clear'
alias ..='cd ..'
alias down="cd ~/Downloads"

# Editor
alias v='nvim'

# Python
alias p='python3'
alias venv='python3 -m venv .venv'
alias src='. .venv/bin/activate'
alias pyserve='python3 -m http.server'

# Claude
alias claude='claude --permission-mode auto'
alias clauder='claude --resume'
alias setup-claude="git clone https://github.com/coleam00/context-engineering-intro .claude && mv .claude/.claude/commands/ .claude/"

# Misc
alias q='echo "tsk tsk"'
alias simple-web-server="simple-web-server --no-sandbox --disable-dev-shm-usage"
alias olink='obsidian-symlink.sh'
alias startday="/home/camer/dotfiles/scripts/startDay.sh"
alias syncandroid="rsync -av --delete ~/Documents/obsidian-vault/ /media/camer/CAMFLASHER/CaracalObsVault"
alias cm='/home/camer/Documents/Projects/tvmtestsmetra/.venv/bin/claude-monitor'
