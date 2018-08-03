" settings

set number
set hlsearch
set wildmenu
set nobackup
set expandtab
set smartcase
set nojoinspaces
set nowritebackup
colorscheme snow

" specifics

set tabstop=4
set shiftwidth=4
set textwidth=79
set laststatus=2
set numberwidth=5
set encoding=utf8
set formatoptions+=t
set background=light
set foldmethod=indent
set foldlevelstart=99
set backspace=indent,eol,start
set notimeout ttimeout ttimeoutlen=200

" let me be free

let mapleader = ','
let g:rehash256 = 1
let g:goyo_width = 100
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_use_caching = 0
"let g:prettier#autoformat = 0
let g:EasyMotion_smartcase = 1
let g:EasyMotion_do_mapping = 0
let g:ctrlp_custom_ignore = 'node_modules'
let g:ackprg = 'ag --nogroup --nocolor --column'
"let g:rufo_auto_formatting = 1 " ruby

" open your heart, mind, and browser

let g:netrw_nogx = 1
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)

" automate the future

augroup formatNewCodeBuffer
    autocmd!
    autocmd BufWrite * :echom "Autostarting..."
    autocmd FileType yaml setlocal sw=2 ts=2 expandtab indentexpr=
    autocmd FileType ruby setlocal sw=2 ts=2 expandtab
    autocmd FileType eruby setlocal sw=2 ts=2 expandtab
    autocmd FileType html setlocal tabstop=2 shiftwidth=2
    autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
    "autocmd FileType javascript setlocal formatprg=prettier\ --stdin
    autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
    autocmd BufNewFile,BufRead *.html setlocal nowrap

    " even prettier
    "autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.vue PrettierAsync
augroup end

