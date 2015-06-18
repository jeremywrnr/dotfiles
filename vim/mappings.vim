" mapping commands to reduce typos
command WQA wqa
command WQa wqa
command Wqa wqa
command WQ wq
command Wq wq
command QA qa
command Qa qa
command W w
command Q q

" smoother motions
map <c-j> 15gj
map <c-k> 15gk
nmap j gj
nmap k gk
noremap H 0
noremap L $

" code folding and unfolding
map <Space>f zR
map <Space>c zM

" function keys
noremap <F3> :w !detex \| wc -w<cr>
noremap <F4> :set number!<cr>
noremap <F5> :setlocal spell! spelllang=en_us<cr>

" normal alias mappings
nmap ; :

" call macros
nmap m @

" managing tabs
nmap tn :tabnew<cr>
nmap tc :tabclose<cr>

" format all lines
nmap FG 1G=G``zz

" trim any lines longer than 80 chars
nmap FI :call ShortenLines()<cr>

" format current paragraph
nmap FP {jV}kJgqq{j

" turn on paste mode
nmap FV :set paste!<cr>

" fix any whitepsace in open file
nmap FW :FixWhitespace<cr>

" normal noremap alias mappings
nnoremap Y y$
nnoremap U <c-r>
nnoremap <Right> >>
nnoremap <Left> <<
nnoremap <s-x> za
nnoremap <c-a> ggVG<cr>
nnoremap <c-y> :%y+<cr>

" NT / easy motion mappings
map <Leader>l <plug>NERDTreeTabsToggle<cr>
map <Leader>f <Plug>(easymotion-s)
map <Leader>s <Plug>(easymotion-s2)
map <Space>j <Plug>(easymotion-j)
map <Space>k <Plug>(easymotion-k)
map <silent> <Space>h :nohl<cr>
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
nmap / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" insert mode remappings
" inoremap jk <Esc>
imap <s-tab> <c-d>
imap <c-s> <esc>:w<cr>
