" vim-plug setup
call plug#begin('~/.vim/plugged')

" github vim bundles
Plug 'tpope/vim-git'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'ervandew/screen'
Plug 'reedes/vim-wordy'
Plug 'danro/rename.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'metakirby5/codi.vim'
Plug 'Raimondi/delimitMate'
Plug 'tyru/open-browser.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-scripts/closetag.vim'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/vim-easy-align'
Plug 'ntpeters/vim-better-whitespace'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'editorconfig/editorconfig-vim'

" aesthetics
Plug 'jeremywrnr/snow'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-emoji'

" language specific
Plug 'sheerun/vim-polyglot'
Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'mustache/vim-mustache-handlebars'

" post installs
Plug 'prettier/vim-prettier', { 'do': 'npm install --legacy-peer-deps' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Add plugins to &runtimepath
call plug#end()
