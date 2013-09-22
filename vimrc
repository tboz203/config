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

" Tommy Bozeman
" 4/8/12
" my personal additions {{{

nohls

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
set backup
" }}}

" tabs {{{
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
" }}}

" Messing around in vim
let mapleader = '-'
let maplocalleader = ','

" normal/visual mode mappings {{{
noremap <leader>t :%s/\s\+$//<cr>
noremap <leader>ev :vsplit $MYVIMRC<cr>
noremap <leader>sv :source $MYVIMRC<cr>
noremap H 0
noremap L $
" }}}

" visual mode mappings {{{
vnoremap <leader>" di""<esc>hp
" }}}

" insert mode mappings {{{
inoremap <c-u> <esc>vbUea
inoremap jk <esc>
inoremap JK <esc>
inoremap kj <esc>
inoremap KJ <esc>
inoremap <esc> jk
" }}}

" abbreviations {{{
iabbrev teh the
iabbrev tboz tboz203
" }}}

" example autocmd {{{
augroup example
    autocmd!
    autocmd BufNewFile,BufRead *.html setlocal nowrap
augroup END
" }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd Filetype vim setlocal foldmethod=marker
augroup END
" }}}

" comment command {{{
augroup comment
    autocmd!
    autocmd Filetype python nnoremap <buffer> <localleader>c 0i#<esc>
    autocmd Filetype sh nnoremap <buffer> <localleader>c 0i#<esc>
    autocmd Filetype java nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype c nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype c++ nnoremap <buffer> <localleader>c 0i//<esc>
    autocmd Filetype vim nnoremap <buffer> <localleader>c 0i"<esc>
augroup END
" }}}

" autocmd abbreviations {{{
augroup abbrevs
    autocmd!
    autocmd Filetype python     :iabbrev <buffer> iff if:<left>
    autocmd Filetype javascript :iabbrev <buffer> iff if ()<left>
augroup END
" }}}

" custom movements {{{
" markdown header movements
" (speaking of which, need to learn markdown, lol)
onoremap ih :<c-u>execute "normal! ?^==\\+\r:nohlsearch\rkvg_"<cr>
onoremap ah :<c-u>execute "normal! ?^==\\+\r:nohlsearch\rg_vk0"<cr>

" next/last email movement
onoremap in@ :<c-u>execute "normal! /\\w\\+@\\w\\+\\.\\w\\+\\(\\.\\w\\+\\)*\r:nohls\rvE"<cr>
onoremap il@ :<c-u>execute "normal! ?\\w\\+@\\w\\+\\.\\w\\+\\(\\.\\w\\+\\)*\r:nohls\rvE"<cr>
" }}}

" }}} personal additions
