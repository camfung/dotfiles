#!/bin/bash
set -e

if command -v claude &>/dev/null; then
  echo "claude already installed: $(claude --version 2>/dev/null || echo 'version check failed')"
  exit 0
fi

# Official native installer — no Node/npm prereq.
# https://docs.claude.com/en/docs/claude-code/setup
if command -v curl &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
elif command -v wget &>/dev/null; then
  wget -qO- https://claude.ai/install.sh | bash
else
  echo "Need curl or wget to install claude"
  exit 1
fi

echo "claude installed: $(claude --version 2>/dev/null || echo 'run claude to verify')"
