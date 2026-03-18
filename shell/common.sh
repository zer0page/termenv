# termenv — shared shell extensions (bash + zsh)

# Platform detection + module config
# Resolve this file's real path to locate platform.sh regardless of symlinks or repo location
if [ -n "${ZSH_VERSION-}" ]; then
  eval '_TERMENV_SELF="${(%):-%x}"'
else
  _TERMENV_SELF="${BASH_SOURCE[0]}"
fi
source "$(dirname "$(readlink -f "$_TERMENV_SELF")")/../platform.sh"
unset _TERMENV_SELF

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
  alias ll='ls -Ghal'
  alias la='ls -Gal'
else
  alias ls='ls --color=auto'
  alias ll='ls --color=auto -hal'
  alias la='ls --color=auto -al'
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
alias yolo='claude --dangerously-skip-permissions'

# Auto-attach to tmux on SSH login
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
  exec tmux attach 2>/dev/null || exec tmux new-session
fi
