"====[ Break long lines into shorter ones ]====================================>
function ShortenLines()
    " search and truncate long lines
    :g/./normal gqq<CR>
    " clear the resulting hightlights
    :nohlsearch
    echom "ShortenLines complete."
endfunction
