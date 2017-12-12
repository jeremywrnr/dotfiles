" mapping commands to reduce typos
command WQA wq
command WQa wq
command Wqa wq
command WQ wq
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

" managing tabs
nmap tn :tabnew<cr>
nmap tc :tabclose<cr>

" format all lines, jump back, center
nmap FG 1G=G``zz

" trim any lines longer than 80 chars
nmap FI :call ShortenLines()<cr>

" format current paragraph
nmap FP {jV}kJgqq{j

" turn on paste mode
nmap FV :set paste!<cr>

" fix any whitepsace in open file
nmap FW :StripWhitespace<cr>

" normal noremap alias mappings
nnoremap Y y$
nnoremap U <c-r>
nnoremap <s-Up> yy2kp2jddkk
nnoremap <s-Down> ddp
nnoremap <Right> >>
nnoremap <Left> <<
nnoremap <s-x> za
nnoremap <c-a> ggVG<cr>
nnoremap <c-y> :%y+<cr>

" NT / easy motion mappings
map <silent> <Space>h :nohl<cr>
map <Leader>f <Plug>(easymotion-s)
map <Leader>s <Plug>(easymotion-s2)
map <Space>j <Plug>(easymotion-j)
map <Space>k <Plug>(easymotion-k)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
nmap / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" insert mode remappings
inoremap jk <Esc>
inoremap kj <Esc>
imap <s-tab> <c-d>
imap <c-s> <esc>:w<cr>

" f8 mapping for vim wordy
noremap <silent> <F8> :<C-u>NextWordy<cr>
xnoremap <silent> <F8> :<C-u>NextWordy<cr>
inoremap <silent> <F8> <C-o>:NextWordy<cr>
