" termenv — Go language module

let g:go_bin_path = expand("~/.gotools")
let g:go_fmt_command = "goimports"
let g:go_fmt_autosave = 0
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" ALE Go linters
let g:ale_linters = get(g:, 'ale_linters', {})
let g:ale_linters['go'] = ['gofmt', 'golint', 'govet', 'errcheck']
