" termenv — keybindings

let mapleader = ","
let g:mapleader = ","

" Fast save
nmap <leader>w :w!<cr>

" Buffer navigation
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>
nnoremap <C-x> <C-W>q

" Remove trailing spaces
nnoremap <Leader>rts :%s/\s\+$//e<CR>

" File browser (vinegar/netrw)
noremap <Leader>n :Explore<CR>

" fzf (replaces ctrlp)
noremap <Leader>p :Files<CR>
noremap <Leader>b :Buffers<CR>
noremap <Leader>/ :Rg<CR>

" EasyMotion
let g:EasyMotion_leader_key = '<Leader><Leader>'

" Fold search
let g:foldsearch_highlight = 1
let g:foldsearch_disable_mappings = 1
noremap <leader>fp :Fp \v
noremap <leader>fl :Fl<cr>
noremap <leader>fu zv
