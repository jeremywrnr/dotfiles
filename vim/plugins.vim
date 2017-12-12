" vim-plug setup
call plug#begin('~/.vim/plugged')

" thank you tpope
Plug 'tpope/vim-git'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'

" github vim bundles
Plug 'kien/ctrlp.vim'
Plug 'ervandew/screen'
Plug 'reedes/vim-wordy'
Plug 'danro/rename.vim'
Plug 'bling/vim-airline'
Plug 'metakirby5/codi.vim'
Plug 'Raimondi/delimitMate'
Plug 'tyru/open-browser.vim'
Plug 'airblade/vim-gitgutter'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-scripts/closetag.vim'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/vim-easy-align'
Plug 'ntpeters/vim-better-whitespace'
Plug 'vim-airline/vim-airline-themes'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'altercation/vim-colors-solarized'
Plug 'editorconfig/editorconfig-vim'

" aesthetics
Plug 'nightsense/snow'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-emoji'

" language specific
Plug 'rking/ag.vim'
Plug 'isRuslan/vim-es6'
Plug 'wavded/vim-stylus'
Plug 'rust-lang/rust.vim'
Plug 'sheerun/vim-polyglot'
Plug 'pangloss/vim-javascript'
Plug 'ruby-formatter/rufo-vim'
Plug 'kchmck/vim-coffee-script'
Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'mustache/vim-mustache-handlebars'

" post installs
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'vue'] }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" this plugin is accursed.
"Plug 'Valloric/YouCompleteMe'
" Fails on => fn
"Plug 'w0rp/ale'
"Plug 'lervag/vimtex'
" some import error.
"Plug 'Valloric/MatchTagAlways'

" Add plugins to &runtimepath
call plug#end()

" initialization
set rtp+=~/.fzf
filetype plugin indent on
set nocompatible
filetype off
syntax on
