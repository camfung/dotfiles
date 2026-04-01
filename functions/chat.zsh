chat() {
  if [ -n "$1" ]; then
    mkdir -p ~/ClaudeChats/"$1"
    cd ~/ClaudeChats/"$1" && claude
  else
    cd ~/ClaudeChats && claude
  fi
}
