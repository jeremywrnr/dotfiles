" vundle setup
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" github vim bundles
Bundle "gmarik/vundle"
Bundle "kien/ctrlp.vim"
Bundle "ervandew/screen"
Bundle "tpope/vim-git"
Bundle "tpope/vim-fugitive"
Bundle "tpope/vim-markdown"
Bundle "tpope/vim-surround"
Bundle "tpope/vim-unimpaired"
Bundle "lervag/vim-latex"
Bundle "bling/vim-airline"
Bundle "danro/rename.vim"
Bundle "scrooloose/nerdtree"
Bundle "jistr/vim-nerdtree-tabs"
Bundle "Valloric/YouCompleteMe"
Bundle "Lokaltog/vim-easymotion"
Bundle "vim-scripts/Vim-R-plugin"
Bundle "scrooloose/nerdcommenter"
Bundle "kchmck/vim-coffee-script"
Bundle "mustache/vim-mustache-handlebars"
Bundle "bronson/vim-trailing-whitespace"

" initialization
call vundle#end()
filetype plugin indent on
syntax on
colorscheme monokai
