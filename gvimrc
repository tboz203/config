" Standard gvimrc "{{{
" An example for a gvimrc file.
" The commands in this are executed when the GUI is started.
"
" Maintainer:   Bram Moolenaar <Bram@vim.org>
" Last change:  2001 Sep 02
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.gvimrc
"             for Amiga:  s:.gvimrc
"  for MS-DOS and Win32:  $VIM\_gvimrc
"           for OpenVMS:  sys$login:.gvimrc

" Make external commands work through a pipe instead of a pseudo-tty
"set noguipty

" set the X11 font to use
" set guifont=-misc-fixed-medium-r-normal--14-130-75-75-c-70-iso8859-1
set guifont=Source\ Code\ Pro\ for\ Powerline

set ch=2                " Make command line two lines high

set mousehide           " Hide the mouse when typing text

" Make shift-insert work like in Xterm
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>

" Only do this for Vim version 5.0 and later.
if version >= 500

  " I like highlighting strings inside C comments
  let c_comment_strings=1

  " Switch on syntax highlighting if it wasn't on yet.
  if !exists("syntax_on")
    syntax on
  endif

  " Switch on search pattern highlighting.
  set hlsearch

  " For Win32 version, have "K" lookup the keyword in a help file
  "if has("win32")
  "  let winhelpfile='windows.hlp'
  "  map K :execute "!start winhlp32 -k <cword> " . winhelpfile <CR>
  "endif

  " Set nice colors
  " background for normal text is light grey
  " Text below the last line is darker grey
  " Cursor is green, Cyan when ":lmap" mappings are active
  " Constants are not underlined but have a slightly lighter background
  highlight Normal guibg=grey90
  highlight Cursor guibg=Green guifg=NONE
  highlight lCursor guibg=Cyan guifg=NONE
  highlight NonText guibg=grey80
  highlight Constant gui=NONE guibg=grey95
  highlight Special gui=NONE guibg=grey95

endif
" }}}

" Tommy Bozeman
" my personal additions

" basic options {{{
colorscheme default
set scrolloff=3         " set minimum number of screen lines to show to three
set cmdheight=1         " set the command area hight to two
set laststatus=2        " set the status-line to always showing
set list
let &listchars = "tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
" set background=dark     " make the text easier to read on a dark background
set background=light    " make the text easier to read on a light background
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

set undofile
set undodir=/tmp

set spellfile=~/.vim/spell/en.utf-8.add
" end basic options }}}

" messing around with mappings {{{
let mapleader = '-'
let maplocalleader = ','

" normal mode
" remove whitespace at end of line
noremap <silent> <leader>rs :%s/\s\+$//<cr>:noh<cr>
" retab the file
noremap <silent> <leader>rt :retab<cr>
" do both
noremap <silent> <leader>rr :retab<cr>:%s/\s\+$//<cr>:noh<cr>
" easy edit/source of my vimrc (this file)
noremap <leader>ev :vsplit $MYVIMRC<cr>
noremap <leader>sv :source $MYVIMRC<cr>
" quick mapping to get rid of search highlighting
noremap <silent> <leader>h :nohlsearch<cr>
" copy to clipboard
noremap <silent> <leader>c "+y
" paste from clipboard
noremap <silent> <leader>p o<esc>"+p
" insert the current date or date and time
noremap <silent> <leader>d :r !day<cr>kJ
noremap <silent> <leader>f :r !full<cr>kJ
" default to using the command window
noremap : q:a
noremap / q/a
noremap ? q?a
" a quick mapping for JSHint
noremap <leader>j :JSHint<cr><cr>
" make a mapping for traditional ex binding
noremap ; :

noremap gl :set list!<cr>
noremap gs :set spell!<cr>
" b/c we use screen so much, give us a mapping to increment
noremap <c-s> <c-a>
" ... and decrement
noremap <c-c> <c-x>

" visual mode
vnoremap <leader>" di""<esc>hp

" insert mode
inoremap <c-u> <esc>vbUea
inoremap jk <esc>
" nerdtree overwrites the digraph binding, so we'll use <c-h> instead.
inoremap <c-h> <c-k>

" end messing around with mappings }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd Filetype vim setlocal foldmethod=marker
augroup END
" }}}

" notes files settings {{{
augroup filetype_notes
    autocmd!
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
" a vimrc starting point
Bundle 'tpope/vim-sensible'
" graphical undo tree
Bundle 'sjl/gundo.vim'
" integration w/ git
Bundle 'tpope/vim-fugitive'
" multi-language block commenting
Bundle 'tpope/vim-commentary'
" quick manipulation of wrapping elements
Bundle 'tpope/vim-surround'
" add repeat (.) support to (some) plugins
Bundle 'tpope/vim-repeat'
" adding gpg symmetric support
Bundle 'vim-scripts/gnupg.vim'
" tmux syntax highlighting
Bundle 'zaiste/tmux.vim'
" a 'fuzzy' code-completion engine
Bundle 'Valloric/YouCompleteMe'
" tag support
Bundle 'majutsushi/tagbar'
" something something binary/hex editing?
Bundle 'tpope/vim-afterimage'

" {{{
" " tern support
" Bundle 'marijnh/tern_for_vim'
" " tag generator using tern
" Bundle 'ramitos/jsctags'
" " auto-set indentation variables
" Bundle 'tpope/vim-sleuth'
" " indentation guides
" Bundle 'nathanaelkane/vim-indent-guides'
" " powerful file-system searching
" Bundle 'kien/ctrlp.vim'
" " buffer explorer
" Bundle 'corntrace/bufexplorer'
" " increment/decrement dates w/ <c-a>/<c-x>
" Bundle 'tpope/vim-speeddating'
" " snippet insertion (for boilerplate code)
" Bundle 'SirVer/ultisnips'
" " file-system browser
" Bundle 'scrooloose/nerdtree'
" " tab-support for nerdtree
" Bundle 'jistr/vim-nerdtree-tabs'
" " javascript helpers
" Bundle 'Shutnik/jshint2.vim'
" Bundle 'walm/jshint.vim'
" Bundle 'vim-scripts/TabBar'
" " external syntax checking (?)
" Bundle 'scrooloose/syntastic'
" " ctags from some other place, lol
" Bundle 'clausreinke/scoped_tags'
" " }}}

filetype plugin indent on
" end Vundle }}}

" " plugin settings {{{
" " UltiSnips tab-completion conflicts with YCM, new triggers for snippet
" " expansion/jumping
" let g:UltiSnipsExpandTrigger = '<c-l>'
" let g:UltiSnipsJumpForwardTrigger = '<c-j>'
" let g:UltiSnipsJumpBackwardTrigger = '<c-k>'

" " indent guide settings
" let g:indent_guides_enable_on_vim_startup = 0
" let g:indent_guides_auto_colors = 0
" autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=darkgrey
" autocmd VimEnter,Colorscheme * :hi IndentGuidesEven NONE
" autocmd VimEnter,Colorscheme * :hi Normal NONE

" gundo setting(s)
let g:gundo_right = 1

" vim-surround settings
" instead of surrounding with 'p' use value from prompt
let g:surround_112 = "\1surround: \1\r\1\1"

" javascript tags
let g:tagbar_type_javascript = { 'ctagsbin': '/usr/local/bin/jsctags' }
" let g:tagbar_type_javascript = { 'ctagsbin': '/home/tommy/config/bin/ejstags' }

" mappings for plugins that don't have these nice settings
noremap <silent> <leader>u :GundoToggle<cr>
noremap <silent> <leader>n :NERDTreeTabsToggle<cr>
noremap <silent> <leader>tt :TagbarToggle<cr>
noremap <silent> <leader>to :TagbarOpen<cr>
noremap <silent> <leader>tc :TagbarClose<cr>


" }}}

" tabs {{{
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
" end tabs }}}

" powerline {{{
" if $HAS_POWERLINE
"     python3 from powerline.vim import setup as powerline_setup
"     python3 powerline_setup()
"     python3 del powerline_setup
" endif
" }}}

" when diff'ing, ignore whitespace
set diffopt+=iwhite

filetype indent on
" vim: sw=4 sts=4 et
