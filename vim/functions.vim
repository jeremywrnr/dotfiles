"====[ Save back up of the current file ]======================================>
nmap <silent>  <c-b>  :call SaveBackup()<CR>
function SaveBackup ()
    let b:backup_count = exists('b:backup_count') ? b:backup_count+1 : 1
    return writefile(getline(1,'$'), bufname('%') . '_' . b:backup_count)
endfunction


"====[ Show when lines extend past column 80 "]================================>
highlight ColorColumn ctermbg=magenta
function! MarkMargin (on)
    if exists('b:MarkMargin')
        try
            call matchdelete(b:MarkMargin)
        catch /./
        endtry
        unlet b:MarkMargin
    endif
    if a:on
        let b:MarkMargin = matchadd('ColorColumn', '\%82v', 100)
    endif
endfunction

augroup MarkMargin
    autocmd!
    autocmd  BufEnter  *       :call MarkMargin(1)
    autocmd  BufEnter  *.vp*   :call MarkMargin(0)
augroup END


"====[ Break long lines into shorter ones ]====================================>
function ShortenLines()
    " search and truncate long lines
    :g/./normal gqq<CR>
    " clear the resulting hightlights
    :nohlsearch
    echom "ShortenLines complete."
endfunction


"====[ Things of python  ]====================================>
" Set options if using spaces for indents (default).
function PySpacesCfg()
    set expandtab
    set tabstop=8
    set softtabstop=4
    set shiftwidth=4
endfunction

" Set options if using tabs for indents.
function PyTabsCfg()
    set noexpandtab
    set tabstop=4
    set softtabstop=4
    set shiftwidth=4
endfunction

" Return 1 if using tabs for indents, or 0 otherwise.
function PyIsTabIndent()
    let lnum = 1
    let got_cols = 0  " 1 if previous lines ended with columns
    while lnum <= 100
        let line = getline(lnum)
        let lnum = lnum + 1
        if got_cols == 1
            if line =~ "^\t\t"  " two tabs to prevent false positives
                return 1
            endif
        endif
        if line =~ ":\s*$"
            let got_cols = 1
        else
            let got_cols = 0
        endif
    endwhile
    return 0
endfunction

" Check current buffer and configure for tab or space indents.
function PyIndentAutoCfg()
    if PyIsTabIndent()
        call PyTabsCfg()
    else
        call PySpacesCfg()
    endif
endfunction


