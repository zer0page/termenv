# termenv — shared shell extensions (bash + zsh)

# Platform detection + module config
# Resolve this file's real path (through symlinks) to locate platform.sh
if [ -n "${ZSH_VERSION-}" ]; then
  eval '_TERMENV_DIR="${${(%):-%x}:A:h}"'
else
  _TERMENV_SELF="${BASH_SOURCE[0]}"
  while [ -L "$_TERMENV_SELF" ]; do
    _TERMENV_LINK="$(readlink "$_TERMENV_SELF")"
    case "$_TERMENV_LINK" in
      /*) _TERMENV_SELF="$_TERMENV_LINK" ;;
      *)  _TERMENV_SELF="$(dirname "$_TERMENV_SELF")/$_TERMENV_LINK" ;;
    esac
  done
  _TERMENV_DIR="$(cd -P "$(dirname "$_TERMENV_SELF")" && pwd -P)"
  unset _TERMENV_SELF _TERMENV_LINK
fi
source "$_TERMENV_DIR/../platform.sh"
unset _TERMENV_DIR

# Defaults
export EDITOR=vim
export VISUAL=vim

# Colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'

# Colors
alias grep='grep --color=auto'
if [ "$TERMENV_OS" = "mac" ]; then
  export CLICOLOR=1
  export LSCOLORS=gxfxcxdxbxegedabagacad
  alias ls='ls -G'
  alias ll='ls -hal'
  alias la='ls -al'
elif [ "$TERMENV_OS" = "linux" ]; then
  alias ls='ls --color=auto'
  alias ll='ls -hal'
  alias la='ls -al'
fi

# History — large (1M lines)
export HISTSIZE=1000000
export SAVEHIST=1000000
export HISTFILE=~/.shell_history

# bat (better cat)
if command -v bat &>/dev/null; then
  alias cat='bat --plain'
fi

# fd (better find)
if command -v fd &>/dev/null; then
  alias find='fd'
fi

# delta (better git diff)
if command -v delta &>/dev/null; then
  export GIT_PAGER='delta'
fi

# fzf — fuzzy finder shell integration
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS='--height 20% --layout=reverse'
  # Use fd for file search if available
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
fi

# Aliases
alias vi='vim'
alias gcan='git commit --amend --no-edit'
yolo() {
  if [ "$1" = "clear" ]; then
    unset CLAUDE_SESSION
    shift
    command claude --dangerously-skip-permissions "$@"
  else
    if [ -z "$CLAUDE_SESSION" ]; then
      if command -v uuidgen &>/dev/null; then
        export CLAUDE_SESSION="$(uuidgen)"
      elif [ -r /proc/sys/kernel/random/uuid ]; then
        export CLAUDE_SESSION="$(cat /proc/sys/kernel/random/uuid)"
      else
        export CLAUDE_SESSION="claude-$$-$(date +%s)"
      fi
    fi
    command claude --dangerously-skip-permissions --continue --name "$CLAUDE_SESSION" "$@"
  fi
}

# Auto-attach to tmux on interactive SSH login
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
  case "$-" in *i*)
    tmux attach 2>/dev/null || tmux new-session
  ;; esac
fi
