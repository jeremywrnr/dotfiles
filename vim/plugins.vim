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
Plug 'kien/ctrlp.vim'
Plug 'ervandew/screen'
Plug 'reedes/vim-wordy'
Plug 'danro/rename.vim'
Plug 'bling/vim-airline'
Plug 'metakirby5/codi.vim'
Plug 'Raimondi/delimitMate'
Plug 'tyru/open-browser.vim'
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
Plug 'jeremywrnr/snow'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-emoji'

" language specific
Plug 'rking/ag.vim'
Plug 'isRuslan/vim-es6'
Plug 'wavded/vim-stylus'
Plug 'sheerun/vim-polyglot'
Plug 'pangloss/vim-javascript'
Plug 'kchmck/vim-coffee-script'
Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'mustache/vim-mustache-handlebars'

" post installs
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'branch': 'release/1.x',
  \ 'for': [
    \ 'javascript',
    \ 'typescript',
    \ 'css',
    \ 'less',
    \ 'scss',
    \ 'json',
    \ 'graphql',
    \ 'markdown',
    \ 'vue',
    \ 'lua',
    \ 'php',
    \ 'python',
    \ 'ruby',
    \ 'html',
    \ 'swift' ] }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Add plugins to &runtimepath
call plug#end()

" initialization
set rtp+=~/.fzf
filetype plugin indent on
set nocompatible
filetype off
syntax on
