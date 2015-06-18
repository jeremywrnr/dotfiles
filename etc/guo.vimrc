" .vimrc for Philip Guo <philip@pgbovine.net>

" currently only works well for VIM 7.0 and above


" Make a better alias for 'Esc' (remember that 'Ctrl [' also works by default)
imap <C-j> <Esc>

map Q <Esc>:q<CR> " Quick exit
map W <Esc>:w<CR> " Quick save

" (Comma makes a great modifier key)
" Move to the head and tail of a block
map ,a {
map ,d }


" Be able to do useful stuff in insert mode ...
imap <C-B> <Left>
imap <C-F> <Right>
" Undo and redo in insert mode
inoremap <C-u> <C-o>u
inoremap <C-r> <C-o><C-R>


" Togle set and unset paste modes
map <C-P> <Esc>:set invpaste paste?<CR>

" enforce one space after period
set nojoinspaces


" Searching
set incsearch
set hlsearch
set ignorecase
set smartcase
" Search and replace:
set gdefault " activates the global 'g' option by default for sed-style search & replace
" Turn off annoying highlighting:
nmap <silent> <C-N> :silent noh<CR>

set scrolloff=3 " keep several lines of context around top/bottom of screen

" allows you to backspace to previous line and over the start of the current Insert invocation
set backspace=2

" map the perennial favorites Ctrl-A, Ctrl-E
map  <C-A> <Home>
map  <C-E> <End>
imap <C-A> <Home>
imap <C-E> <End>


" Tabs and indentation and stuff
set autoindent
set shiftwidth=2
set smarttab
set expandtab
set tabstop=2

" Exception for Makefiles - use real Tabs rather than spaces
au FileType make setlocal noexpandtab
au FileType make set formatoptions=lc

" Don't highlight syntax on HTML in order to expose spellchecking errors
" that otherwise don't show up for some weird font reason
" nix that
"au BufRead *.htm,*.html syntax off

au FileType stp syntax off
au FileType stp setlocal nospell

" Don't spell check source files
au BufRead *.py,*.c,*.h,*.cpp,*.sh,*.js,*.ts setlocal nospell
" Only indent comments
au BufRead *.py,*.c,*.h,*.cpp,*.sh,*.js,*.ts set formatoptions=lc

" to conform more to PEP8
au BufRead *.py set shiftwidth=4

" syntax highlight typescript like javascript
au BufRead,BufNewFile *.ts set filetype=javascript

au BufRead *.tex setlocal spell spelllang=en

" Turn spellchecking on by default
setlocal spell spelllang=en

" cindent is the stupidest ass thing EVER when not editing C files!!!
au BufRead *.c,*.cpp,*.cc,*.h set cindent shiftwidth=2

" use B to break line (J to join lines)
:nmap B i<CR><Esc>

"quickly move between split windows
nmap <C-j> <C-W>j
nmap <C-k> <C-W>k
nmap <c-h> <c-w>h
nmap <c-l> <c-w>l


" Word wrapping
set lbr
set textwidth=72

set formatoptions=tcq
"set formatoptions=l

" F7 turns on word wrapping, F8 turns it off
map <F7> <Esc>:set formatoptions=tcq<CR>
map <F8> <Esc>:set formatoptions=l<CR>


" Spell checking

" F5 turns on spell checking, F6 turns it off, have it on by default
map <F5> <Esc>:setlocal spell spelllang=en<CR>
map <F6> <Esc>:setlocal nospell<CR>

setlocal spell spelllang=en " enable spell-checking by default
setlocal spellcapcheck= " don't worry about checking for capitalization errors
" Make the spell checker colors not as ugly as heck - instead, use underlining
hi SpellBad cterm=underline ctermfg=white ctermbg=black
hi SpellRare cterm=underline ctermfg=white ctermbg=black
hi SpellLocal cterm=underline ctermfg=white ctermbg=black


" Status line and ruler
set laststatus=2 " keep status line always visible
set ruler " so you can see line numbers
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " a ruler on steroids


" Syntax highlighting
syntax enable
set background=dark " apparently this leads to better highlighting for dark backgrounds


" Dealing with files and buffers

" Opening new files
set wildmode=longest,list,full
" set wildmode=longest,list
set wildignore=*.o,*.obj,*.bak,*.exe
set writebackup

:set hidden             " don't unload current buffer when changing buffers

" switching between open buffers
" buffer navigation:
" ":e <filename>" to make a buffer with that file in it (duh)
" ",s" and ",f" for back and forth on the buffer list
" ",1", ",2", .. ",9", ",0" to go straight to that numbered buffer (0 = 10)
" ",g" to toggle between two buffers (my most used probably)
map ,s :bN!<CR>
map ,f :bn!<CR>
map ,g :e!#<CR>
map ,1 :1b<CR>
map ,2 :2b<CR>
map ,3 :3b<CR>
map ,4 :4b<CR>
map ,5 :5b<CR>
map ,6 :6b<CR>
map ,7 :7b<CR>
map ,8 :8b<CR>
map ,9 :9b<CR>
map ,0 :10b<CR>

" Ummmm, forget about using the mouse ...
"set mouse=ar

" Fill paragraph - emulate Emacs Meta-Q
imap <C-g> <C-o>ma<C-o>vapgq<C-o>'a
" does ma and 'a to restore cursor back to original spot after
" paragraph filling
map <C-g> mavapgq'a

" useful stuff from this tips site:
"   http://items.sjbach.com/319/configuring-vim-right

"nnoremap " `

" keep a longer history
set history=1000

set title

" to enable per-file modelines --- wtf need to set to 5??!!!???!!!???!!!
set modeline
set modelines=5

" from Damian Conway's OSCON 2013 talk: http://www.youtube.com/watch?v=aHm36-na4-4
" hitting shift is annoying!
"nnoremap ' "
nnoremap ; :

" highlight anything over 80 chars with a color
highlight ColorColumn ctermbg=magenta
call matchadd('ColorColumn', '\%81v', 100)
