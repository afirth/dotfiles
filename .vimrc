iset nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" assorted plugins
Plugin 'scrooloose/syntastic'
Plugin 'altercation/vim-colors-solarized'
Plugin 'tpope/vim-fugitive'

"ruby
" Plugin 'tpope/vim-rails'
" Plugin 'thoughtbot/vim-rspec'
" Plugin 'tpope/vim-bundler'

"golang
Plugin 'fatih/vim-go'
Plugin 'mdempsky/gocode', {'rtp': 'vim/'}

"autocomplete with tab
Plugin 'ervandew/supertab'
":set completeopt=longest,menuone

" send commands to tmux
"Plugin 'jgdavey/tslime.vim'

" autoformat yaml
Plugin 'avakhov/vim-yaml'

" python folding is screwed
Plugin 'tmhedberg/SimpylFold' "folding
"autocomplete, esp for python
"Plugin 'davidhalter/jedi-vim' 

" comment blocks <Leader>c<space> to toggle
Plugin 'scrooloose/nerdcommenter'
" \c<space>
let g:NERDSpaceDelims = 1

" smart tabs - tabs at line start, spaces for variable alignment
" :RetabIndent[!]
Plugin 'Smart-Tabs'

" Default markdown support is borked
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
let g:vim_markdown_new_list_item_indent = 0

" shows indent guides in colors
"Plugin 'nathanaelkane/vim-indent-guides'
" Turn off indent guides
let g:indent_guides_enable_on_vim_startup = 0

" Elixir
"Plugin 'elixir-lang/vim-elixir'
"Plugin 'mattreduce/vim-mix'

" Terraform
"Plugin 'hashivim/vim-terraform'

call vundle#end()
" Regular config resumes here

syntax on
set background=dark
"set background=light
" let g:solarized_visibility = "high"
" let g:solarized_contrast = "high"
let g:solarized_termtrans = 1
colorscheme solarized

set encoding=utf-8

"search settings (/ ?)
"use space to turn off search highlighting
nnoremap <Space> :noh<cr><Space>
set hlsearch
set ignorecase
set smartcase

filetype plugin on

" TABS AND SPACING
filetype plugin indent on

set backspace=2   " more powerful backspacing
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab

autocmd Filetype php setlocal noexpandtab tabstop=4 shiftwidth=4

" personal and system specific setup

set splitright
"fix scrolling in iterm hopefully
set mouse=a
if has("mouse_sgr")
    set ttymouse=sgr
else
    set ttymouse=xterm2
end
" bind the " register (def) to the OS clipboard
" :version must have +clipboard. Use vim, not vi, on osx homebrew. vim 7.4+
set clipboard+=unnamed

autocmd CursorHold * checktime
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

let g:CommandTMaxFiles=20000
let g:CommandTMaxCachedDirectories=3

if has('gui_running')
    set guifont=Menlo:h12    " set fonts for gui vim
    set transparency=1        " set transparent window
endif

"disable all error bells and flashing
set vb t_vb=

" Folding
set foldmethod=syntax
set foldcolumn=0
set foldnestmax=1
"set foldlevelstart=20
" fix folds reverting on every write due to go_fmt
let g:go_fmt_experimental = 1

" ignore annoying obviously bad paths for ctrl p
set wildignore+=*.o,*.obj,*.swp,.git,.svn,tmp,log,.sass-cache,public,coverage,tests,content,node_modules

" yankring somewhere not stupid
let g:yankring_history_dir = '~/.yankring'

" rspec bindings
map <F5> :w<CR>:call RunCurrentSpecFile()<CR>
map <F6> :w<CR>:call RunNearestSpec()<CR>
map <F7> :call RunLastSpec()<CR>

" Open spec in vertical split
command! AA execute "vsplit | A"

" quickly open spec in new tab
" always show status line
set laststatus=2

"set nowrap
set wrap
set lbr

" sensible indent for html
let g:html_indent_inctags = "html,body,head,tbody"

" don't let Command T traverse SCM
let g:CommandTTraverseSCM = "pwd"

" splitjoin awesome
nnoremap \ :SplitjoinSplit<cr>
nnoremap <c-\> :SplitjoinJoin<cr>

" help with jumping around lines
"set relativenumber
set nu

" disable markdown auto folding
" who actually thinks this is a great user experience?
let g:vim_markdown_folding_disabled=1

" sensible pane switching
nmap <silent> <A-Up> :wincmd k<CR>
nmap <silent> <A-Down> :wincmd j<CR>
nmap <silent> <A-Left> :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>

" see column count
set ruler

" change leader to something easier
"let mapleader= ","

" easier movement
"map <leader>h :wincmd h<CR>
"map <leader>j :wincmd j<CR>
"map <leader>k :wincmd k<CR>
"map <leader>l :wincmd l<CR>

" no more .swp in project tree
":set directory=$HOME/.vim/swapfiles

" Work around Syntastic bug
" command E Ex

" Show long line warning/critical marker
"let &colorcolumn="80,".join(range(120,999),",")

" Fuzzy finding
set rtp+=~/.fzf

" ctrl p search mapping
map <leader>t :FZF<CR>

" Just in case fzf isn't working
" Plugin 'ctrlpvim/ctrlp.vim'
" map <leader>t :CtrlP<CR>

syntax on               " enable syntax highlighting
set cursorline          " highlight the current line
" set background=dark   " darker color scheme
" set ruler             " show line number in bar
set nobackup            " don't create pointless backup files; Use VCS instead
set autoread            " watch for file changes
set number              " show line numbers
set showcmd             " show selection metadata
set showmode            " show INSERT, VISUAL, etc. mode
set showmatch           " show matching brackets
set autoindent smartindent  " auto/smart indent
set smarttab            " better backspace and tab functionality
set scrolloff=5         " show at least 5 lines above/below
filetype on             " enable filetype detection
filetype indent on      " enable filetype-specific indenting
filetype plugin on      " enable filetype-specific plugins
" colorscheme cobalt      " requires cobalt.vim to be in ~/.vim/colors

" column-width visual indication
let &colorcolumn=join(range(81,999),",")
highlight ColorColumn ctermbg=235 guibg=#001D2F

" tabs and indenting
set autoindent          " auto indenting
set smartindent         " smart indenting
set expandtab           " spaces instead of tabs
set tabstop=2           " 2 spaces for tabs
set shiftwidth=2        " 2 spaces for indentation

" bells
set noerrorbells        " turn off audio bell
set visualbell          " but leave on a visual bell

" search
set hlsearch            " highlighted search results
set showmatch           " show matching bracket

" other
set guioptions=aAace    " don't show scrollbar in MacVim
" call pathogen#infect()  " use pathogen

" clipboard
set clipboard=unnamed   " allow yy, etc. to interact with OS X clipboard

" shortcuts
map <F2> :NERDTreeToggle<CR>

" remapped keys
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
inoremap {{     {
inoremap {}     {}
