# shellcheck shell=bash
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
  command -v dircolors &>/dev/null && eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias ll='ls -hal'
  alias la='ls -al'
fi

# History — large (1M lines), use each shell's default HISTFILE
export HISTSIZE=1000000
if [ -n "${ZSH_VERSION-}" ]; then
  export SAVEHIST=$HISTSIZE
else
  export HISTFILESIZE=$HISTSIZE
fi

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

# Git branch for prompt — works in bash and zsh, silent outside repos
# Color matches Prism: default branch → green, feature branches → yellow
# Called once per prompt via PROMPT_COMMAND (bash) or precmd_functions (zsh),
# not during PS1/PROMPT expansion, so it never clobbers $?.
__git_branch() {
  command -v git >/dev/null || return
  local branch default
  # symbolic-ref: branch name on normal HEAD, exits non-zero on detached/non-repo
  # rev-parse --short: short SHA fallback for detached HEAD
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return
  # Resolve remote default branch; fall back to main/master for local-only repos
  default=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  default="${default##*/}"
  case "$default" in
    '') case "$branch" in main|master) default="$branch" ;; esac ;;
  esac
  if [ -n "${ZSH_VERSION-}" ]; then
    # Escape % so branch names can't inject zsh prompt escape sequences
    local escaped="${branch:gs/%/%%}"
    [ "$branch" = "$default" ] && printf ' %%{\e[32m%%}(%s)%%{\e[0m%%}' "$escaped" \
                                || printf ' %%{\e[33m%%}(%s)%%{\e[0m%%}' "$escaped"
  else
    # \001/\002 wrap non-printing chars so bash counts prompt width correctly
    [ "$branch" = "$default" ] && printf ' \001\e[32m\002(%s)\001\e[0m\002' "$branch" \
                                || printf ' \001\e[33m\002(%s)\001\e[0m\002' "$branch"
  fi
}

# Aliases
alias vi='vim'
alias gcan='git commit --amend --no-edit'
# shellcheck disable=SC2262  # alias may not exist; failure sent to /dev/null
unalias yolo 2>/dev/null
yolo() {
  command claude --dangerously-skip-permissions "$@"
}

# Auto-attach to tmux on interactive SSH login
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && command -v tmux &>/dev/null; then
  case "$-" in *i*)
    tmux attach 2>/dev/null || tmux new-session
  ;; esac
fi
