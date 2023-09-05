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

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " set comments properly
  autocmd FileType helm setlocal commentstring=#\ %s

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
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
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
let &listchars = "tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
" set listchars=tab:>-,trail:-,extends:$,precedes:$
set background=dark     " make the text easier to read on a dark background
set modeline            " if a file has a modeline, use it
set splitbelow          " put new windows to the right or below
set splitright
set number              " do line numbering
set numberwidth=5
set foldcolumn=1
set nowrap              " set linewrapping to behave in an intelligent manner
set linebreak
set textwidth=119
set ignorecase
set smartcase
set shiftround
set cursorline

set sidescroll=20
set sidescrolloff=20

set undofile
set undodir=$HOME/.vim/undodir

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

set tags=./tags;,./.tags;

set directory=~/.vim/swap//,.

set history=10000

set wildmode=longest,list

let python_highlight_all = 1

" set nofixeol

" set spellfile=~/.vim/spell/en.utf-8.add

" end basic options }}}

" if version > "500"

    if version > "800"
        set diffopt+=iwhite,algorithm:patience
    endif

    " messing around with mappings {{{
    let mapleader = '-'
    let maplocalleader = ','

    " normal mode
    " remove whitespace at end of line
    noremap <silent> <leader>rs :%s/\s\+$//<cr>:noh<cr><C-o>
    " retab the file
    noremap <silent> <leader>rt :retab<cr><C-o>
    " remove extra <CR> characters
    noremap <silent> <leader>rn :%s/\r$//<cr><C-o>
    " do all
    noremap <silent> <leader>rr :retab<cr>:%s/\s*\r\?$//<cr>:noh<cr><C-o>
    " toggle line wrapping
    noremap <silent> <leader>w :set wrap!<cr>
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

    " noremap <leader>p :set paste!<cr>
    " mnemonic: 'text long'
    noremap <leader>tl :set tw=119<cr>
    " mnemonic: 'text short'
    noremap <leader>ts :set tw=79<cr>
    " mnemonic: 'text zero'
    noremap <leader>tz :set tw=0<cr>

    " default to using the command window
    noremap : :<c-f>a
    " noremap / /<c-f>a
    " noremap ? ?<c-f>a
    " a quick mapping for JSHint
    noremap <leader>j :JSHint<cr><cr>
    " make a mapping for traditional ex binding
    noremap ; :

    noremap gl :set list!<cr>
    noremap gs :set spell!<cr>
    " " b/c we use screen so much, give us a mapping to increment
    " noremap <c-s> <c-a>
    " " ... and decrement
    " noremap <c-c> <c-x>

    " create folds for block under cursor
    noremap <leader>c V%zf

    " visual mode
    vnoremap <leader>" di""<esc>hp

    " insert mode
    inoremap <c-u> <esc>vbUea
    inoremap jk <esc>
    " nerdtree overwrites the digraph binding, so we'll use <c-h> instead.
    inoremap <c-h> <c-k>

    " make ZQ quit harder
    noremap ZQ :cq!<cr>

    " let's make searching always center the cursor
    noremap n nzz
    noremap N Nzz

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
    if isdirectory(expand("$HOME/.vim/bundle/Vundle.vim"))
        filetype off

        set rtp+=$HOME/.vim/bundle/Vundle.vim
        call vundle#rc()

        " vundle itself
        Bundle 'VundleVim/Vundle.vim'
        " a vimrc starting point
        Bundle 'tpope/vim-sensible'
        " graphical undo tree
        Bundle 'dsummersl/gundo.vim'
        " integration w/ git
        Bundle 'tpope/vim-fugitive'
        " multi-language block commenting
        Bundle 'tpope/vim-commentary'
        " quick manipulation of wrapping elements
        Bundle 'tpope/vim-surround'
        " add repeat (.) support to (some) plugins
        Bundle 'tpope/vim-repeat'
        " tag window
        Bundle 'preservim/tagbar'
        " auto-set indentation variables
        Bundle 'tpope/vim-sleuth'

        Bundle 'nathanaelkane/vim-indent-guides'

        " 'Tabularize' alignment
        Bundle 'godlygeek/tabular'
        " " external syntax checking (?)
        " Bundle 'scrooloose/syntastic'

        Bundle 'vim-scripts/AnsiEsc.vim'

        Bundle 'sheerun/vim-polyglot'

        Bundle 'noah/vim256-color'

        Bundle 'editorconfig/editorconfig-vim'

        " code completion + goto support
        Bundle 'ycm-core/YouCompleteMe'

        " file-system browser
        Bundle 'scrooloose/nerdtree'
        " tab-support for nerdtree
        Bundle 'jistr/vim-nerdtree-tabs'

        Bundle 'keepcase.vim'

        " cucumber step jump
        Bundle 'tpope/vim-cucumber'

        " Bundle 'zaiste/tmux.vim'
        " Bundle 'pangloss/vim-javascript'
        " Bundle 'mxw/vim-jsx'
        " Bundle 'leafgarland/typescript-vim'
        " Bundle 'fatih/vim-go'
        " Bundle 'ekalinin/Dockerfile.vim'
        " Bundle 'hashivim/vim-vagrant'
        " Bundle 'hashivim/vim-terraform'
        " Bundle 'chr4/nginx.vim'
        " Bundle 'PProvost/vim-ps1'
        " Bundle 'rodjek/vim-puppet'
        " Bundle 'robbles/logstash.vim'
        " Bundle 'martinda/Jenkinsfile-vim-syntax'

        " Bundle 'mustache/vim-mustache-handlebars'

        " Bundle 'dylon/vim-antlr'
        " Bundle 'RobRoseKnows/lark-vim'

        " " adding gpg symmetric support
        " Bundle 'vim-scripts/gnupg.vim'
        "
        " " rudimentary image editing
        " Bundle 'tpope/vim-afterimage'
        " " tern support
        " Bundle 'marijnh/tern_for_vim'
        " " tag generator using tern
        " Bundle 'ramitos/jsctags'
        " " powerful file-system searching
        " Bundle 'kien/ctrlp.vim'
        " " buffer explorer
        " Bundle 'corntrace/bufexplorer'
        " " increment/decrement dates w/ <c-a>/<c-x>
        " Bundle 'tpope/vim-speeddating'
        " " snippet insertion (for boilerplate code)
        " Bundle 'SirVer/ultisnips'
        " " javascript helpers
        " Bundle 'Shutnik/jshint2.vim'
        " Bundle 'walm/jshint.vim'
        " Bundle 'vim-scripts/TabBar'
        " " ctags from some other place, lol
        " Bundle 'clausreinke/scoped_tags'

        filetype plugin indent on
        " end Vundle }}}

        " plugin settings {{{
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

        " mundo setting(s)
        let g:mundo_right = 1

        " vim-surround settings
        " instead of surrounding with 'p' use value from prompt
        let g:surround_112 = "\1surround: \1\r\1\1"

        " javascript tags
        let g:tagbar_type_javascript = { 'ctagsbin': '/usr/local/bin/jsctags' }
        " let g:tagbar_type_javascript = { 'ctagsbin': '/home/tommy/config/bin/ejstags' }

        " syntastic settings
        let g:syntastic_check_on_wq = 0
        let g:syntastic_mode_map = {
            \ "mode": "passive",
            \ "active_filetypes": [],
            \ "passive_filetypes": [] }
        let g:syntastic_python_python_exec = 'python3'
        let g:syntastic_python_checkers = ['python', 'flake8']

        let g:ycm_goto_buffer_command = 'split-or-existing-window'
        let g:ycm_confirm_extra_conf = 0
        let g:ycm_python_interpreter_path = ''
        let g:ycm_python_sys_path = []
        let g:ycm_disable_for_files_larger_than_kb = 1000
        let g:ycm_extra_conf_vim_data = [
            \   'g:ycm_python_interpreter_path',
            \   'g:ycm_python_sys_path'
            \ ]
        " let g:ycm_filetype_blacklist = {
        "     \   'sql': 1,
        "     \   'log': 1,
        "     \   'json': 1
        "     \ }
            " \     'cmdline': ['bundle', 'exec', 'solargraph', 'stdio'],
        let g:ycm_language_server =
            \ [
            \   {
            \     'name': 'ruby',
            \     'filetypes': ['ruby'],
            \     'cmdline': ['env', 'RBENV_VERSION=3.1.2', 'solargraph', 'stdio'],
            \     'project_root_files': ['Rakefile', 'Gemfile', '.solargraph.yml']
            \   }
            \ ]
        let g:ycm_keep_logfiles = 1


        " mappings for plugins that don't have these nice settings
        noremap <silent> <leader>u :MundoToggle<cr>
        noremap <silent> <leader>n :NERDTreeTabsToggle<cr>
        noremap <silent> <leader>tt :TagbarToggle<cr>
        noremap <silent> <leader>to :TagbarOpen<cr>
        noremap <silent> <leader>tc :TagbarClose<cr>

        noremap <silent> <leader>a :AnsiEsc<cr>
        noremap <silent> <leader>A :AnsiEsc!<cr>

        noremap <silent> <leader>se :Errors<cr>
        noremap <silent> <leader>sc :SyntasticCheck<cr>
        noremap <silent> <leader>st :SyntasticToggleMode<cr>
        noremap <silent> <leader>si :SyntasticInfo<cr>
        noremap <silent> <leader>sr :SyntasticReset<cr>

        noremap <leader>D :YcmCompleter GetDoc<cr>
        noremap <leader>GR :YcmCompleter GoToReferences<cr>
        noremap <leader>GG :YcmCompleter GoTo<cr>
        noremap <leader>GS :vsplit<cr>:YcmCompleter GoTo<cr>
        noremap <leader>GT :tab YcmCompleter GoTo<cr>
        " need to type a new name, so trailing space instead of <cr>,
        exec "noremap <leader>RR :YcmCompleter RefactorRename\x20"

        noremap <leader>gd :Gvdiffsplit<cr>
        noremap <leader>gb :Git blame<cr>

        " align vim-commentary w/ other comment bindings
        vnoremap <C-_> :'<,'>Commentary<cr>

        " colorscheme babymate256
        " colorscheme Chasing_Logic
        " colorscheme Tomorrow-Night
        " colorscheme Tomorrow-Night-Eighties
        colorscheme apprentice
        " colorscheme atom-dark-256
        " colorscheme badwolf
        " colorscheme bubblegum-256-dark
        " colorscheme darkula
        " colorscheme desert
        " colorscheme iceberg
        " colorscheme kolor
        " colorscheme lilypink
        " colorscheme molokai
        " colorscheme muon
        " colorscheme neverland
        " colorscheme neverland2
        " colorscheme slate
        " colorscheme wombat256mod

        filetype indent on

    endif

    " }}}

    " " tabs {{{
    " set shiftwidth=4
    " set softtabstop=4
    " set expandtab
    " set smarttab
    " " end tabs }}}

    " powerline {{{
    if $HAS_POWERLINE
        python3 import sys; sys.path.append("/usr/local/lib/python3.6/site-packages")
        python3 << trim endpython
            try:
                from powerline.vim import setup as powerline_setup
                powerline_setup()
                del powerline_setup
            except ImportError:
                pass
        endpython
    endif
    " }}}

" endif
" vim: sw=4 sts=4 et fdm=marker


" let b:cucumber_steps_glob = '%:p:h:s?.*[\/].*step.*\zs[\/].*??'
