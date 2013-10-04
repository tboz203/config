" An example for a vimrc file.
" vim: sw=4 sts=4 et filetype=vim
"
" Maintainer:   Bram Moolenaar <Bram@vim.org>
" Last change:  2008 Dec 17
"
" To use it, copy it to
"     for Unix and OS/2:      ~/.vimrc
"     for Amiga:              s:.vimrc
"     for MS-DOS and Win32:   $VIM\_vimrc
"     for OpenVMS:            sys$login:.vimrc

" Standard vimrc {{{
" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
    finish
endif

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set history=50      " keep 50 lines of command line history
set ruler       " show the cursor position all the time
set showcmd     " display incomplete commands
set incsearch       " do incremental searching

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
    set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
  nohlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 76 characters.
  autocmd FileType text setlocal textwidth=76

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
  augroup END

else
  set autoindent        " always set autoindenting on
endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
          \ | wincmd p | diffthis
endif
" end standard vimrc }}}

" Tommy Bozeman
" my personal additions

" basic options {{{
set scrolloff=3         " set minimum number of screen lines to show to three
set cmdheight=1         " set the command area hight to two
set laststatus=2        " set the status-line to always showing
set listchars=tab:>-,trail:-,precedes:$,extends:$      " set up list mode
set list
set background=dark     " make the text easier to read on a dark background
set modeline            " if a file has a modeline, use it
set splitbelow          " put new windows to the right or below
set splitright
set number              " do line numbering
set numberwidth=5
set foldcolumn=1
set nowrap              " set linewrapping to behave in an intelligent manner
set linebreak
set textwidth=79
set ignorecase
set smartcase
set shiftround
"set backup
" end basic options }}}

" tabs {{{
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
" end tabs }}}

" messing around with mappings {{{
let mapleader = '-'
let maplocalleader = ','
" end messing around with mappings }}}

" normal/visual mode mappings {{{
noremap <leader>t :%s/\s\+$//<cr>
noremap <leader>ev :vsplit $MYVIMRC<cr>
noremap <leader>sv :source $MYVIMRC<cr>
noremap H 0
noremap L $
noremap K H
noremap J L
noremap <leader>j J
noremap <leader>k K
noremap <leader>n :nohlsearch<cr>
noremap <c-o> o<esc>
noremap <c-O> O<esc>
" end normal/visual mode mappings }}}

" visual mode mappings {{{
vnoremap <leader>" di""<esc>hp
" end visual mode mappings }}}

" insert mode mappings {{{
" still not sure if i want the jk trick :/
inoremap <c-u> <esc>vbUea
inoremap jk <esc>
inoremap <c-j> <down>
inoremap <c-k> <up>
inoremap <c-h> <left>
inoremap <c-l> <right>
" end insert mode mappings }}}

" abbreviations {{{
iabbrev teh the
iabbrev tboz tboz203
" end abbreviations }}}

" short section of html commands {{{
augroup example
    autocmd!
    autocmd BufNewFile,BufRead *.html setlocal nowrap
    autocmd BufNewFile,BufRead *.html setlocal tw=0
augroup END
" end short section of html commands }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd Filetype vim setlocal foldmethod=marker
augroup END
" end vimscript file settings }}}

" comment command {{{
augroup comment
    autocmd!
    autocmd Filetype python nnoremap <buffer> <localleader>c 0i#<esc>
    autocmd Filetype python nnoremap <buffer> <localleader>C 0x
    autocmd Filetype sh nnoremap <buffer> <localleader>c 0i#<esc>
    autocmd Filetype sh nnoremap <buffer> <localleader>C 0x
    autocmd Filetype java nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype java nnoremap <buffer> <localleader>C 0xx
    autocmd Filetype c nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype c nnoremap <buffer> <localleader>C 0xx
    autocmd Filetype c++ nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype c++ nnoremap <buffer> <localleader>C 0xx
    autocmd Filetype vim nnoremap <buffer> <localleader>c 0i"<esc>
    autocmd Filetype vim nnoremap <buffer> <localleader>C 0x
    autocmd Filetype javascript nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype javascript nnoremap <buffer> <localleader>C 0xx
augroup END
" end comment command }}}

" autocmd abbreviations {{{
augroup abbrevs
    autocmd!
    autocmd Filetype python     :iabbrev <buffer> iff if:<left>
    autocmd Filetype javascript :iabbrev <buffer> iff if ()<left>
    autocmd Filetype java       :iabbrev <buffer> iff if (){<left><left>
    autocmd Filetype c          :iabbrev <buffer> iff if (){<left><left>
    autocmd Filetype cpp        :iabbrev <buffer> iff if (){<left><left>
augroup END
" end autocmd abbreviations }}}

" html abbreviations {{{
" Not working at present.
"augroup html_abbrevs
"    autocmd!
"    autocmd Filetype html       :iabbrev <buffer> /html \</html\>
"    autocmd Filetype html       :iabbrev <buffer> html \<html\>
"    autocmd Filetype html       :iabbrev <buffer> /head \</head\>
"    autocmd Filetype html       :iabbrev <buffer> head \<head\>
"    autocmd Filetype html       :iabbrev <buffer> /title \</title\>
"    autocmd Filetype html       :iabbrev <buffer> title \<title\>
"    autocmd Filetype html       :iabbrev <buffer> /body \</body\>
"    autocmd Filetype html       :iabbrev <buffer> body \<body\>
"    autocmd Filetype html       :iabbrev <buffer> /script \</script\>
"    autocmd Filetype html       :iabbrev <buffer> script \<script\>
"    autocmd Filetype html       :iabbrev <buffer> /p \</p\>
"    autocmd Filetype html       :iabbrev <buffer> p \<p\>
"    autocmd Filetype html       :iabbrev <buffer> /div \</div\>
"    autocmd Filetype html       :iabbrev <buffer> div \<div\>
"    autocmd Filetype html       :iabbrev <buffer> /span \</span\>
"    autocmd Filetype html       :iabbrev <buffer> span \<span\>
"    autocmd Filetype html       :iabbrev <buffer> /button \</button\>
"    autocmd Filetype html       :iabbrev <buffer> button \<button\>
"augroup END
" end html abbreviations }}}

" custom movements {{{
" next/last parentheses movement
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>

" markdown header movements
onoremap ih :<c-u>execute "normal! ?^==\\+\r:nohlsearch\rkvg_"<cr>
onoremap ah :<c-u>execute "normal! ?^==\\+\r:nohlsearch\rg_vk0"<cr>

" next/last email movement
onoremap in@ :<c-u>execute "normal! /\\w\\+@\\w\\+\\.\\w\\+\\(\\.\\w\\+\\)*\r:nohls\rvE"<cr>
onoremap il@ :<c-u>execute "normal! ?\\w\\+@\\w\\+\\.\\w\\+\\(\\.\\w\\+\\)*\r:nohls\rvE"<cr>
" end custon movements }}}
