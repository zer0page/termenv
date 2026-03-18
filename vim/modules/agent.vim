" termenv — Agent/AI-native vim settings
" Optimizes vim for use alongside AI coding agents (Claude Code, etc.)

" Auto-reload files changed externally by agents
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif

" Bracketed paste mode (proper paste from agents)
if &t_BE == ''
  let &t_BE = "\e[?2004h"
  let &t_BD = "\e[?2004l"
  let &t_PS = "\e[200~"
  let &t_PE = "\e[201~"
endif

" Let tmux handle mouse when agent is active
set mouse=

" Reduce updatetime for faster CursorHold (file change detection)
set updatetime=300
