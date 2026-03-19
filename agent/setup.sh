#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Usage:
#   ./agent/setup.sh              Install
#   ./agent/setup.sh --uninstall  Uninstall
#
# Installs Claude Code and Prism status line.
# Can be run standalone or called from install.sh.

set -e

#==============
# Uninstall
#==============
if [ "$1" = "--uninstall" ]; then
  echo "Uninstalling agent tooling..."

  if [ -f "$HOME/.claude/prism" ]; then
    rm "$HOME/.claude/prism"
    echo "  Removed prism"
  fi

  echo "  Claude Code left installed (uninstall manually if desired)"
  echo "  ~/.claude/settings.json left in place"
  exit 0
fi

#==============
# Install
#==============
echo "Setting up agent tooling..."

# Install Claude Code
if ! command -v claude &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "  Installing Claude Code via brew..."
    brew install claude-code
  elif command -v npm &>/dev/null; then
    echo "  Installing Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code
  else
    echo "  WARNING: Cannot install Claude Code (need brew or npm)"
  fi
else
  echo "  Claude Code already installed"
fi

# Install Prism status line
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/prism" ]; then
  echo "  Installing Prism status line..."
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')

  if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    PRISM_ARCH="arm64"
  else
    PRISM_ARCH="amd64"
  fi

  if [ "$OS" = "darwin" ] || [ "$OS" = "linux" ]; then
    PRISM_TARGET="${OS}-${PRISM_ARCH}"
  fi

  if [ -n "$PRISM_TARGET" ]; then
    if curl -fsSL "https://github.com/himattm/prism/releases/latest/download/prism-${PRISM_TARGET}" -o "$HOME/.claude/prism"; then
      chmod +x "$HOME/.claude/prism"
      echo "  Prism installed"
    else
      rm -f "$HOME/.claude/prism"
      echo "  WARNING: Failed to download Prism (skipping)"
    fi
  else
    echo "  WARNING: Unsupported platform for Prism ($OS/$ARCH)"
  fi
else
  echo "  Prism already installed"
fi

echo "Agent tooling setup complete!"
