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
" end basic options }}}

" tabs {{{
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
" end tabs }}}

" abbreviations {{{
abbreviate teh the
abbreviate hlep help
abbreviate ivm vim
abbreviate functino function
abbreviate fiel file
abbreviate thsi this
" }}}

" messing around with mappings {{{
let mapleader = '-'
let maplocalleader = ','

" normal mode
noremap <silent> <leader>rs :%s/\s\+$//<cr>:noh<cr>
" retab the file
noremap <silent> <leader>rt :retab<cr>
" do both
noremap <silent> <leader>rr :retab<cr>:%s/\s\+$//<cr>:noh<cr>
" easy edit/source of my vimrc (this file)
noremap <leader>ev :vsplit $MYVIMRC<cr>
noremap <leader>sv :source $MYVIMRC<cr>
" quick mapping to get rid of search highlighting
noremap <silent> <leader>n :nohlsearch<cr>
" default to using the command window
noremap : q:a
noremap / q/a
noremap ? q?a

" visual mode
vnoremap <leader>" di""<esc>hp

" insert mode
inoremap <c-u> <esc>vbUea
inoremap jk <esc>
" end messing around with mappings }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd Filetype vim setlocal foldmethod=marker
augroup END
" }}}

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
" }}}

" Vundle {{{
filetype off

set rtp+=~/.vim/bundle/vundle
call vundle#rc()
" vundle itself
Bundle 'gmarik/vundle'

" plugins {{{
" a vimrc starting point
Bundle 'tpope/vim-sensible'
" auto-set indentation variables
Bundle 'tpope/vim-sleuth'
" snippet insertion (for boilerplate code)
Bundle 'SirVer/ultisnips'
" file-system browser
Bundle 'scrooloose/nerdtree'
" tab-support for nerdtree
Bundle 'jistr/vim-nerdtree-tabs'
" graphical undo tree
Bundle 'sjl/gundo.vim'
" integration w/ git
Bundle 'tpope/vim-fugitive'
" easy commenting
Bundle 'tpope/vim-commentary'
" powerful file-system searching
Bundle 'kien/ctrlp.vim'
" end plugins }}}

filetype plugin indent on
" end Vundle }}}

" plugin settings {{{
" UltiSnips tab-completion conflicts with YCM, new triggers for snippet
" expansion/jumping
let g:UltiSnipsExpandTrigger = '<c-l>'
let g:UltiSnipsJumpForwardTrigger = '<c-j>'
let g:UltiSnipsJumpBackwardTrigger = '<c-k>'

" gundo setting(s)
let g:gundo_right = 1

" mappings for plugins that don't have these nice settings
noremap <leader>u :GundoToggle<cr>
noremap <leader>t :NERDTreeTabsToggle<cr>
" }}}
