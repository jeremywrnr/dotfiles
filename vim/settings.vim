" settings

set number
set hlsearch
set expandtab
set smartcase
set wildmenu
set nobackup
set nojoinspaces
set nowritebackup

" specifics

set tabstop=4
set shiftwidth=4
set textwidth=79
set encoding=utf-8
set laststatus=2
set numberwidth=5
set foldmethod=indent
set foldlevelstart=99
set formatoptions+=t
set backspace=indent,eol,start
set notimeout ttimeout ttimeoutlen=200

" let me be free

let mapleader = ','
let g:rehash256 = 1
let g:airline_section_y = ''
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline#extensions#tabline#left_sep = ''
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:EasyMotion_smartcase = 1
let g:EasyMotion_do_mapping = 0
let NERDTreeShowBookmarks = 1

" file specific rules

autocmd FileType html setlocal shiftwidth=2 tabstop=2
autocmd FileType python setl sw=2 sts=2 et
