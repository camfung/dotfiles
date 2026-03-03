# Two-line prompt: path on top, everything else below
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_PROMPT_ORDER=(
  dir
  time
  git
  venv

  char
)

# Dir on its own line via a newline suffix
SPACESHIP_DIR_TRUNC=0
SPACESHIP_DIR_TRUNC_REPO=false
SPACESHIP_DIR_PREFIX=''
SPACESHIP_DIR_SUFFIX=$'\n'

# Display time in hh:mm:ss format
SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_FORMAT='%D{%H:%M:%S}'
SPACESHIP_TIME_PREFIX=''

# Display username always
SPACESHIP_USER_SHOW=always
SPACESHIP_USER_PREFIX=''

# Git - no prefix words
SPACESHIP_GIT_PREFIX=''


# Venv - no prefix, always show actual venv name
SPACESHIP_VENV_PREFIX=''
SPACESHIP_VENV_GENERIC_NAMES=()
