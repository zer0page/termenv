#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Usage:
#   ./agent/setup.sh              Install
#   ./agent/setup.sh --uninstall  Uninstall
#
# Installs Claude Code and Prism status line.
# Can be run standalone or called from install.sh when TERMENV_AGENT=1.

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
    brew install claude
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

  if [ "$OS" = "darwin" ]; then
    if [ "$ARCH" = "arm64" ]; then
      PRISM_TARGET="aarch64-apple-darwin"
    else
      PRISM_TARGET="x86_64-apple-darwin"
    fi
  elif [ "$OS" = "linux" ]; then
    PRISM_TARGET="x86_64-unknown-linux-gnu"
  fi

  if [ -n "$PRISM_TARGET" ]; then
    curl -fsSL "https://github.com/himattm/prism/releases/latest/download/prism-${PRISM_TARGET}" -o "$HOME/.claude/prism"
    chmod +x "$HOME/.claude/prism"
    echo "  Prism installed"
  else
    echo "  WARNING: Unsupported platform for Prism ($OS/$ARCH)"
  fi
else
  echo "  Prism already installed"
fi

echo "Agent tooling setup complete!"
