set textwidth=0
set tabstop=2
set shiftwidth=2

" inverting bold and italic, because putty can't do true italics it seems,
" and emphasizes italics *way* more than bold
" copied from vim81 syntax/html
hi htmlBold                term=italic cterm=italic gui=italic
hi htmlBoldUnderline       term=italic,underline cterm=italic,underline gui=italic,underline
hi htmlBoldItalic          term=italic,bold cterm=italic,bold gui=italic,bold
hi htmlBoldUnderlineItalic term=italic,bold,underline cterm=italic,bold,underline gui=italic,bold,underline
hi htmlUnderline           term=underline cterm=underline gui=underline
hi htmlUnderlineItalic     term=bold,underline cterm=bold,underline gui=bold,underline
hi htmlItalic              term=bold cterm=bold gui=bold
