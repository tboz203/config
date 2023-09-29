function! s:authlog_options()
    silent! source /usr/local/lib/i_dont_know_where_to_put_this/auth.log.regex
    set nomodifiable readonly bt=nofile
endfunction

au BufNewFile,BufRead auth.log{,.[1-9]{,.gz}} call s:authlog_options()
