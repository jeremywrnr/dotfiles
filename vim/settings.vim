" settings

set number
set hlsearch
set wildmenu
set nobackup
set expandtab
set smartcase
set nojoinspaces
set nowritebackup
colorscheme solarized

" specifics

set tabstop=4
set shiftwidth=4
set textwidth=79
set laststatus=2
set numberwidth=5
set encoding=utf8
set formatoptions+=t
set background=dark
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
let g:airline_section_y = ''
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_theme = 'cool'
let g:EasyMotion_smartcase = 1
let g:EasyMotion_do_mapping = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ''
let g:ctrlp_custom_ignore = 'node_modules'
let g:ackprg = 'ag --nogroup --nocolor --column'
let g:ycm_python_binary_path="/usr/bin/python3"
let g:ycm_server_python_interpreter="/usr/bin/python3"
let g:ycm_path_to_python_interpreter="/usr/bin/python3"

" js concealing characters

let g:javascript_conceal_function             = "ƒ"
let g:javascript_conceal_null                 = "ø"
let g:javascript_conceal_this                 = "@"
let g:javascript_conceal_return               = "⇚"
let g:javascript_conceal_undefined            = "¿"
let g:javascript_conceal_NaN                  = "ℕ"
let g:javascript_conceal_prototype            = "¶"
let g:javascript_conceal_static               = "•"
let g:javascript_conceal_super                = "Ω"
let g:javascript_conceal_arrow_function       = "⇒"
let g:javascript_conceal_noarg_arrow_function = "🞅"
let g:javascript_conceal_underscore_arrow_function = "🞅"

" open your heart, mind, and browser

let g:netrw_nogx = 1
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)

" automate the future

augroup formatNewCodeBuffer
    autocmd!
    autocmd BufWrite * :echom "Autostarting..."
    autocmd FileType yaml setlocal indentexpr=
    autocmd FileType yaml setlocal sw=2 ts=2 expandtab
    autocmd FileType ruby setlocal sw=2 ts=2 expandtab
    autocmd FileType eruby setlocal sw=2 ts=2 expandtab
    autocmd FileType html setlocal tabstop=2 shiftwidth=2
    autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
    autocmd FileType javascript set formatprg=prettier\ --stdin
    autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
    autocmd BufNewFile,BufRead *.html setlocal nowrap
augroup end

