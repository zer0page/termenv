#!/usr/bin/env bash
# termenv — agent/AI tooling setup
# Usage:
#   ./agent/setup.sh              Install
#   ./agent/setup.sh --uninstall  Uninstall
#
# Installs Claude Code and Prism status line.
# Can be run standalone or called from install.sh.

set -eo pipefail

PRISM_INSTALL_URL="https://raw.githubusercontent.com/himattm/prism/main/install.sh"

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

      # Build updated JSON in a temp file; write atomically to avoid truncating on jq error
      TMP_SETTINGS=$(mktemp)
      _cleanup_settings() { rm -f "$TMP_SETTINGS"; }
      trap _cleanup_settings EXIT

      # Remove statusLine only if it was set by Prism (command starts with prism path)
      if ! jq --arg cmd "$HOME/.claude/prism" '
        if (.statusLine.command // "") | startswith($cmd)
        then del(.statusLine)
        else . end
      ' "$SETTINGS" > "$TMP_SETTINGS" 2>/dev/null; then
        echo "  WARNING: settings.json may be invalid JSON — skipping Prism config cleanup."
        exit 0
      fi

      # Remove hook entries whose command starts with the Prism binary path
      for EVENT in $PRISM_HOOKS; do
        if ! jq --arg e "$EVENT" --arg cmd "$PRISM_CMD" '
          if .hooks[$e] then
            .hooks[$e] |= map(select((.command // "") | startswith($cmd) | not))
            | if .hooks[$e] == [] then del(.hooks[$e]) else . end
          else . end
        ' "$TMP_SETTINGS" > "${TMP_SETTINGS}.next" 2>/dev/null; then
          echo "  WARNING: jq error processing hooks — skipping remaining hook cleanup."
          break
        fi
        mv "${TMP_SETTINGS}.next" "$TMP_SETTINGS"
      done

      if jq 'if .hooks == {} then del(.hooks) else . end' "$TMP_SETTINGS" > "${TMP_SETTINGS}.next" 2>/dev/null; then
        mv "${TMP_SETTINGS}.next" "$TMP_SETTINGS"
        mv "$TMP_SETTINGS" "$SETTINGS"
        echo "  Removed Prism config from settings.json"
      else
        echo "  WARNING: jq error finalizing settings — skipping write to avoid data loss."
      fi
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

# Install Prism status line (via official install script, pinned to immutable commit SHA)
echo "  Installing Prism status line..."
_install_prism() {
  local tmp
  tmp=$(mktemp)
  # Ensure temp file is cleaned up regardless of outcome
  trap "rm -f '$tmp' '${tmp}.x'" RETURN

  # Download to temp file so curl failures are caught (avoids silent curl|bash failures)
  if ! curl -fsSL "$PRISM_INSTALL_URL" -o "$tmp"; then
    return 1
  fi

  # Run installer; capture exit status without letting set -e abort the parent
  if ! bash "$tmp"; then
    return 1
  fi
}
if ! _install_prism; then
  echo "  WARNING: Prism install failed — skipping. You can install manually: https://github.com/himattm/prism"
fi

echo "Agent tooling setup complete!"
