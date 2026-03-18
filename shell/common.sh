# termenv — shared shell extensions (bash + zsh)

# Platform detection + module config
source ~/Development/termenv/platform.sh

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
export CLICOLOR=1
export LSCOLORS=gxfxcxdxbxegedabagacad
alias grep='grep --color=auto'

# History — large (1M lines)
export HISTSIZE=1000000
export SAVEHIST=1000000
export HISTFILE=~/.shell_history

# bat (better cat)
if command -v bat &>/dev/null; then
  alias cat='bat --plain'
fi

# ls with colors
alias ls='ls -G'
alias ll='ls -Ghal'
alias la='ls -Gal'

# fd (better find)
if command -v fd &>/dev/null; then
  alias find='fd'
fi

# delta (better git diff)
if command -v delta &>/dev/null; then
  export GIT_PAGER='delta'
fi

# Aliases
alias vi='vim'
alias gcan='git commit --amend --no-edit'
alias yolo='claude --dangerously-skip-permissions'
