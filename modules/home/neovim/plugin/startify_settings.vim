" Custom Startify settings to remove line numbers and gutter
augroup StartifyCustomSettings
  autocmd!
  autocmd User Startified setlocal nonumber norelativenumber signcolumn=no colorcolumn=0
  autocmd FileType startify setlocal nonumber norelativenumber signcolumn=no colorcolumn=0
augroup END

" Clear cursor line in Startify buffers
autocmd FileType startify setlocal nocursorline

" Remove the ~ markers for unfilled space
autocmd FileType startify setlocal fillchars+=eob:\ 