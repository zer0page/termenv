#!/usr/bin/env bash
# termenv installer/uninstaller
# Usage:
#   ./install.sh              Install
#   ./install.sh --uninstall  Uninstall

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/platform.sh"

SYMLINKS=(
  "$HOME/.vimrc:$DIR/vim/vimrc"
  "$HOME/.vim/termenv/plugins.vim:$DIR/vim/plugins.vim"
  "$HOME/.vim/termenv/keys.vim:$DIR/vim/keys.vim"
  "$HOME/.vim/termenv/modules/go.vim:$DIR/vim/modules/go.vim"
  "$HOME/.vim/termenv/modules/rust.vim:$DIR/vim/modules/rust.vim"
  "$HOME/.vim/termenv/modules/agent.vim:$DIR/vim/modules/agent.vim"
  "$HOME/.vim/termenv/platform/mac.vim:$DIR/vim/platform/mac.vim"
  "$HOME/.vim/termenv/platform/linux.vim:$DIR/vim/platform/linux.vim"
  "$HOME/.tmux.conf:$DIR/tmux/tmux.conf"
  "$HOME/.tmux/termenv/keys.conf:$DIR/tmux/keys.conf"
  "$HOME/.tmux/termenv/mouse.conf:$DIR/tmux/mouse.conf"
  "$HOME/.tmux/termenv/status.conf:$DIR/tmux/status.conf"
  "$HOME/.tmux/termenv/modules/agent.conf:$DIR/tmux/modules/agent.conf"
  "$HOME/.tmux/termenv/platform/mac.conf:$DIR/tmux/platform/mac.conf"
  "$HOME/.tmux/termenv/platform/linux.conf:$DIR/tmux/platform/linux.conf"
  "$HOME/.zsh/termenv/zshrc:$DIR/shell/zshrc"
  "$HOME/.zsh/termenv/common.sh:$DIR/shell/common.sh"
  "$HOME/.bash/termenv/bashrc:$DIR/shell/bashrc"
  "$HOME/.bash/termenv/common.sh:$DIR/shell/common.sh"
)

link_one() {
  local target="$1" source="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "  Already linked: $target"
  elif [ -e "$target" ]; then
    echo "  WARNING: $target already exists (backup and remove to link)"
  else
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    echo "  Linked: $target"
  fi
}

unlink_one() {
  local target="$1" source="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    rm "$target"
    echo "  Removed: $target"
  elif [ -L "$target" ]; then
    echo "  Skipped $target (points elsewhere)"
  elif [ -e "$target" ]; then
    echo "  Skipped $target (not a symlink)"
  fi
}

#==============
# Uninstall
#==============
if [ "$1" = "--uninstall" ]; then
  echo "Uninstalling termenv..."

  for entry in "${SYMLINKS[@]}"; do
    unlink_one "${entry%%:*}" "${entry##*:}"
  done

  rmdir "$HOME/.vim/termenv/modules" "$HOME/.vim/termenv/platform" "$HOME/.vim/termenv" 2>/dev/null || true
  rmdir "$HOME/.tmux/termenv/modules" "$HOME/.tmux/termenv/platform" "$HOME/.tmux/termenv" 2>/dev/null || true
  rmdir "$HOME/.zsh/termenv" 2>/dev/null || true
  rmdir "$HOME/.bash/termenv" 2>/dev/null || true

  [ -d "$HOME/.vim/plugged" ] && echo "  Remove ~/.vim/plugged manually if desired"
  [ -f "$HOME/.vim/autoload/plug.vim" ] && echo "  Remove ~/.vim/autoload/plug.vim manually if desired"
  [ -d "$HOME/.tmux/plugins/tpm" ] && echo "  Remove ~/.tmux/plugins/ manually if desired"

  # Remove source lines from shell rcs
  if [ -f "$HOME/.zshrc" ] && grep -qF 'source ~/.zsh/termenv/zshrc' "$HOME/.zshrc"; then
    sed -i '' '/# termenv shell extensions/d;/source ~\/.zsh\/termenv\/zshrc/d' "$HOME/.zshrc"
    echo "  Removed source line from ~/.zshrc"
  fi
  if [ -f "$HOME/.bashrc" ] && grep -qF 'source ~/.bash/termenv/bashrc' "$HOME/.bashrc"; then
    sed -i '' '/# termenv shell extensions/d;/source ~\/.bash\/termenv\/bashrc/d' "$HOME/.bashrc"
    echo "  Removed source line from ~/.bashrc"
  fi

  echo "Done. Your ~/.termenv.conf was left in place."
  exit 0
fi

#==============
# Install
#==============
echo "Installing termenv ($TERMENV_OS)..."

# Install CLI tools
if command -v brew &>/dev/null; then
  for tool in vim tmux zoxide bat fd git-delta lnav tig ripgrep fzf; do
    if ! brew list "$tool" &>/dev/null; then
      echo "  Installing $tool..."
      brew install "$tool"
    fi
  done
elif command -v apt-get &>/dev/null; then
  for tool in vim tmux zoxide bat fd-find git-delta lnav tig ripgrep fzf; do
    if ! command -v "$tool" &>/dev/null; then
      echo "  Installing $tool (may need sudo)..."
      sudo apt-get install -y "$tool" 2>/dev/null || echo "  Skipped $tool (not in apt)"
    fi
  done
fi

# Install vim-plug
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  Installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Install tpm
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "  Installing tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Create all symlinks
for entry in "${SYMLINKS[@]}"; do
  link_one "${entry%%:*}" "${entry##*:}"
done

# Create default termenv.conf
if [ ! -f "$HOME/.termenv.conf" ]; then
  cat > "$HOME/.termenv.conf" << 'CONF'
# termenv module configuration
# Set to 1 to enable, 0 or remove to disable

# Language modules
TERMENV_VIM_GO=0
TERMENV_VIM_RUST=0

# Agent-native support (for AI coding agents like Claude Code)
TERMENV_AGENT=1
CONF
  echo "  Created ~/.termenv.conf (edit to enable modules)"
fi

# Wire shell extensions into .zshrc
ZSH_SOURCE='source ~/.zsh/termenv/zshrc'
if [ -f "$HOME/.zshrc" ] && ! grep -qF "$ZSH_SOURCE" "$HOME/.zshrc"; then
  echo "" >> "$HOME/.zshrc"
  echo "# termenv shell extensions" >> "$HOME/.zshrc"
  echo "$ZSH_SOURCE" >> "$HOME/.zshrc"
  echo "  Added source line to ~/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
  echo "  Already sourced in ~/.zshrc"
fi

# Wire shell extensions into .bashrc
BASH_SOURCE_LINE='source ~/.bash/termenv/bashrc'
if [ -f "$HOME/.bashrc" ] && ! grep -qF "$BASH_SOURCE_LINE" "$HOME/.bashrc"; then
  echo "" >> "$HOME/.bashrc"
  echo "# termenv shell extensions" >> "$HOME/.bashrc"
  echo "$BASH_SOURCE_LINE" >> "$HOME/.bashrc"
  echo "  Added source line to ~/.bashrc"
elif [ -f "$HOME/.bashrc" ]; then
  echo "  Already sourced in ~/.bashrc"
fi

# Agent setup (if enabled)
source "$HOME/.termenv.conf" 2>/dev/null
if [ "${TERMENV_AGENT:-0}" = "1" ]; then
  "$DIR/agent/setup.sh"
fi

# Install vim plugins (non-interactive)
echo "  Installing vim plugins..."
vim -es -u "$HOME/.vimrc" -i NONE -c "PlugInstall" -c "qa" || true

echo ""
echo "termenv installed successfully!"
echo "  - Edit ~/.termenv.conf to enable modules"
echo "  - Restart tmux or press prefix+r to reload"
