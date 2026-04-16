---
alwaysApply: true
---

# Module Placement

Where new functionality goes:

- **One-liner conveniences** → add to `aliases.zsh`
- **Multi-step operations or stateful functions** → own file in `functions/<name>.zsh` (auto-sourced by zshrc glob)
- **Standalone executables needing PATH** → `scripts/<name>` (add symlink in `install.sh`)
- **Tool configs** → `config/<tool>/` or `config/<tool>.toml` (add symlink in `install.sh`)
- **Machine-specific overrides** → `~/.machine-local.zsh` (not tracked; template in `machine-local.zsh.example`)
- **Machine-specific env vars** → `~/.env.local` (not tracked; template in `env.local.example`)
- **New PATH entries or exports** → `env.zsh`
