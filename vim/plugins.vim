" vim-plug setup
call plug#begin('~/.vim/plugged')

" github vim bundles
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'Raimondi/delimitMate'
Plug 'tyru/open-browser.vim'
Plug 'easymotion/vim-easymotion'
Plug 'ntpeters/vim-better-whitespace'
Plug 'editorconfig/editorconfig-vim'

" aesthetics
Plug 'jeremywrnr/snow'
Plug 'junegunn/goyo.vim'

" post installs
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Add plugins to &runtimepath
call plug#end()
