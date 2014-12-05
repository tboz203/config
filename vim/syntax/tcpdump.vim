
" ^\d{2}:\d{2}:\d{2}\.\d{6} (IP|IP6) \S+ > \S+: [^,]+(, [^,]*)*?, length \d+$

syntax clear
syntax case match

syntax match time       /\v^\d\d:\d\d:\d\d\.\d{6}/ display
syntax match ipversion  /\v\s+(IP6?)/ display
syntax match fromto     /\v\S+\s*\>\s*\S+/ contains=address
syntax match info       /\v:@<= [^,:>]+(,[^,]+)*/
" hostname address
syntax match address    /\v @<=(\w+[.-])*\d*\a+\d*/ nextgroup=altport contained display
" IPv4 address
syntax match address    /\v @<=\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ nextgroup=port contained display
" IPv6 address
syntax match address    /\v @<=\x{,4}((:\x{1,4})*:(:\x{1,4})*|(:\x{1,4}))*([: ])@=/ contained display
syntax match port       /\v\.\w+/
syntax match altport    /\v\.\d+/

hi link time            Constant
hi link ipversion       Identifier
hi link address         Underlined
hi link port            Special
hi link altport         Special
hi link info            Statement
