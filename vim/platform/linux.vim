" termenv — Linux-specific vim settings

" Use system clipboard (X11/Wayland)
if has('unnamedplus')
  set clipboard=unnamedplus
else
  set clipboard=unnamed
endif
