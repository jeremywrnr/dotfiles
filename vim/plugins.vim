" vim-plug setup
call plug#begin('~/.vim/plugged')

" thank you tpope
Plug 'tpope/vim-git'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'

" github vim bundles
Plug 'w0rp/ale'
Plug 'kien/ctrlp.vim'
Plug 'ervandew/screen'
Plug 'reedes/vim-wordy'
Plug 'danro/rename.vim'
Plug 'bling/vim-airline'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-emoji'
Plug 'metakirby5/codi.vim'
Plug 'Raimondi/delimitMate'
Plug 'tyru/open-browser.vim'
" Plug 'Valloric/YouCompleteMe'
Plug 'airblade/vim-gitgutter'
Plug 'Valloric/MatchTagAlways'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-scripts/closetag.vim'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/vim-easy-align'
Plug 'ntpeters/vim-better-whitespace'
Plug 'vim-airline/vim-airline-themes'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'altercation/vim-colors-solarized'
Plug 'editorconfig/editorconfig-vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" language specific
Plug 'rking/ag.vim'
Plug 'lervag/vimtex'
Plug 'isRuslan/vim-es6'
Plug 'wavded/vim-stylus'
Plug 'rust-lang/rust.vim'
Plug 'sheerun/vim-polyglot'
Plug 'pangloss/vim-javascript'
Plug 'kchmck/vim-coffee-script'
Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'mustache/vim-mustache-handlebars'

" Add plugins to &runtimepath
call plug#end()

" initialization
set rtp+=~/.fzf
filetype plugin indent on
set nocompatible
filetype off
syntax on
