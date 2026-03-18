# CLAUDE.md — Instructions for AI agents working on termenv

## Core rule
**Never change keybindings or existing behavior** unless explicitly asked. This includes vim mappings, tmux prefix/bindings, shell aliases, and plugin configurations. Users have muscle memory — breaking it is worse than any improvement.

## Project structure
- `vim/` — vim config, sourced via symlinks under `~/.vim/termenv/`
- `tmux/` — tmux config, sourced via symlinks under `~/.tmux/termenv/`
- `shell/` — bash/zsh extensions, sourced via symlinks under `~/.zsh/termenv/` and `~/.bash/termenv/`
- `agent/` — Claude Code and AI agent setup (Prism, etc.)
- `shared/` — cross-tool constants
- `platform.sh` — OS detection (mac/linux), sets clipboard commands
- `install.sh` — symlinks everything, installs CLI tools, wires shell source lines
- `~/.termenv.conf` — user's module toggles (Go, Rust, agent)

## Conventions
- Piecewise config: each concern is its own file, symlinked individually
- Modules are opt-in via `~/.termenv.conf` env vars
- Platform differences handled in `platform/` subdirectories
- All CLI tool usage is conditional (`command -v` checks)
- install.sh must be idempotent — safe to run multiple times
- `--uninstall` must cleanly reverse everything install does

## Testing changes
- `./install.sh --uninstall && ./install.sh` should be a clean round-trip
- Vim: opens without errors, `:PlugStatus` shows all plugins
- Tmux: `prefix+r` reloads without errors
- Shell: new terminal session sources extensions without errors
