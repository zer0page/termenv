#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Usage:
#   ./agent/setup.sh              Install
#   ./agent/setup.sh --uninstall  Uninstall
#
# Installs Claude Code and Prism status line.
# Can be run standalone or called from install.sh.

set -eo pipefail

# Pinned to Prism v0.10.1 to avoid unpinned supply-chain risk
PRISM_VERSION="v0.10.1"
PRISM_INSTALL_URL="https://raw.githubusercontent.com/himattm/prism/${PRISM_VERSION}/install.sh"

#==============
# Uninstall
#==============
if [ "$1" = "--uninstall" ]; then
  echo "Uninstalling agent tooling..."

  if [ -f "$HOME/.claude/prism" ]; then
    rm "$HOME/.claude/prism"
    echo "  Removed prism"
  fi

  SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    if ! command -v jq &>/dev/null; then
      echo "  WARNING: jq not found — cannot clean up Prism config from settings.json. Remove manually."
    else
      PRISM_CMD="$HOME/.claude/prism hook"
      PRISM_HOOKS="UserPromptSubmit Stop SessionStart SessionEnd PreCompact Setup PreToolUse PostToolUse PermissionRequest Notification SubagentStop"

      # Remove statusLine only if it was set by Prism (command starts with prism path)
      MERGED=$(jq --arg cmd "$HOME/.claude/prism" '
        if (.statusLine.command // "") | startswith($cmd)
        then del(.statusLine)
        else . end
      ' "$SETTINGS")

      # Remove hook entries whose command starts with the Prism binary path
      for EVENT in $PRISM_HOOKS; do
        MERGED=$(echo "$MERGED" | jq --arg e "$EVENT" --arg cmd "$PRISM_CMD" '
          if .hooks[$e] then
            .hooks[$e] |= map(select((.command // "") | startswith($cmd) | not))
            | if .hooks[$e] == [] then del(.hooks[$e]) else . end
          else . end
        ')
      done

      MERGED=$(echo "$MERGED" | jq 'if .hooks == {} then del(.hooks) else . end')
      echo "$MERGED" > "$SETTINGS"
      echo "  Removed Prism config from settings.json"
    fi
  fi

  echo "  Claude Code left installed (uninstall manually if desired)"
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

# Install Prism status line (via official install script, pinned to $PRISM_VERSION)
echo "  Installing Prism status line (${PRISM_VERSION})..."
_install_prism() {
  # Download to a temp file so curl failures are detected (pipefail-safe)
  local tmp
  tmp=$(mktemp)
  if curl -fsSL "$PRISM_INSTALL_URL" -o "$tmp"; then
    bash "$tmp"
    rm -f "$tmp"
  else
    rm -f "$tmp"
    return 1
  fi
}
if ! _install_prism; then
  echo "  WARNING: Prism install failed — skipping. You can install manually: https://github.com/himattm/prism"
fi

echo "Agent tooling setup complete!"
