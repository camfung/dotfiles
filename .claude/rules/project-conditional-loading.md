---
paths: ["zshrc", "aliases.zsh", "env.zsh", "functions/**/*"]
---

# Conditional Loading

All optional tool integrations must use `command -v` guards so zshrc sources cleanly on any machine:

```zsh
if command -v <tool> &>/dev/null; then
  # aliases, eval, export — only when tool is installed
fi
```

Never hard-require external tools in tracked dotfiles. Required env vars for scripts use `: "${VAR:?message}"` guard pattern (see `startDay.sh`).
