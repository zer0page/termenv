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

  SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
    PRISM_HOOKS="UserPromptSubmit Stop SessionStart SessionEnd PreCompact Setup PreToolUse PostToolUse PermissionRequest Notification SubagentStop"
    MERGED=$(jq 'del(.statusLine)' "$SETTINGS")
    for EVENT in $PRISM_HOOKS; do
      MERGED=$(echo "$MERGED" | jq --arg e "$EVENT" --arg cmd '$HOME/.claude/prism hook' '
        if .hooks[$e] then
          .hooks[$e] |= map(select(.hooks[]?.command | startswith($cmd) | not))
          | if .hooks[$e] == [] then del(.hooks[$e]) else . end
        else . end
      ')
    done
    MERGED=$(echo "$MERGED" | jq 'if .hooks == {} then del(.hooks) else . end')
    echo "$MERGED" > "$SETTINGS"
    echo "  Removed Prism config from settings.json"
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

# Install Prism status line (via official install script)
echo "  Installing Prism status line..."
if command -v jq &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/himattm/prism/main/install.sh | bash
else
  echo "  WARNING: jq not found — installing jq first..."
  if command -v brew &>/dev/null; then
    brew install jq
    curl -fsSL https://raw.githubusercontent.com/himattm/prism/main/install.sh | bash
  else
    echo "  WARNING: Cannot install jq (need brew). Skipping Prism."
  fi
fi

echo "Agent tooling setup complete!"
