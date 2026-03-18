" termenv — Rust language module

let g:rustfmt_autosave = 0

" ALE Rust linters
let g:ale_linters = get(g:, 'ale_linters', {})
let g:ale_linters['rust'] = ['cargo', 'rustc']
