" termenv — vim-plug plugin declarations
" Managed by: https://github.com/junegunn/vim-plug

call plug#begin('~/.vim/plugged')

" Theme
Plug 'junegunn/seoul256.vim'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Linting (replaces syntastic)
Plug 'dense-analysis/ale'

" Fuzzy finder (replaces ctrlp)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Navigation
Plug 'christoomey/vim-tmux-navigator'
Plug 'Lokaltog/vim-easymotion'

" File browser (enhances built-in netrw)
Plug 'tpope/vim-vinegar'

" Commenter
Plug 'scrooloose/nerdcommenter'

" Makes . repeat work with plugin actions
Plug 'tpope/vim-repeat'

" Git gutter (shows +/-/~ for changed lines)
Plug 'airblade/vim-gitgutter'

" Auto-detect indentation
Plug 'tpope/vim-sleuth'

" Fold search
Plug 'embear/vim-foldsearch'

" Language modules — loaded conditionally
if $TERMENV_VIM_GO == '1'
  Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
endif

if $TERMENV_VIM_RUST == '1'
  Plug 'rust-lang/rust.vim'
endif

call plug#end()
