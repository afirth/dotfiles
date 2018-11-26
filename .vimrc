set nocompatible              " be iMproved, required
filetype off                  " required

" Configure vundle
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

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

Plugin 'ervandew/supertab' "autocomplete with tab
":set completeopt=longest,menuone

"Plugin 'jgdavey/tslime.vim' " send commands to tmux

" Folding, comments, and formatting plugins
Plugin 'avakhov/vim-yaml' " autoformat yaml
Plugin 'tmhedberg/SimpylFold' "folding
"Plugin 'davidhalter/jedi-vim' "autocomplete, esp for python
Plugin 'scrooloose/nerdcommenter' " Comment blocks: \c<space> to toggle
let g:NERDSpaceDelims = 1

Plugin 'Smart-Tabs' " Smart tabs - tabs at line start, spaces for variable alignment
"to use: :RetabIndent[!]

" Markdown
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
let g:vim_markdown_new_list_item_indent = 0 " don't indent list items
let g:vim_markdown_folding_disabled=1 " disable markdown auto folding

"Plugin 'nathanaelkane/vim-indent-guides' " shows indent guides in colors
let g:indent_guides_enable_on_vim_startup = 0 " Turn off indent guides

" Elixir
"Plugin 'elixir-lang/vim-elixir'
"Plugin 'mattreduce/vim-mix'

" Terraform
"Plugin 'hashivim/vim-terraform'

call vundle#end() " Regular config resumes here


"" File handling
set encoding=utf-8
autocmd CursorHold * checktime
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

"" Appearance
set cursorline          " highlight the current line
set laststatus=2        " always show status line
set number              " show line numbers
set ruler               " show line number in bar
set scrolloff=5         " show at least 5 lines above/below
set showcmd             " show selection metadata
set showmode            " show INSERT, VISUAL, etc. mode
set splitright          "default to vsplit

" Wrapping
set wrap           " wrap long lines (on display)
set lbr            " break at a sensible character (on display)
"set textwidth=80   " actually break

" Colorscheme
set background=dark
"set background=light
" let g:solarized_visibility = "high"
" let g:solarized_contrast = "high"
let g:solarized_termtrans = 1
colorscheme solarized

" Folding
set foldmethod=syntax
set foldcolumn=0
set foldnestmax=1
"set foldlevelstart=20
let g:go_fmt_experimental = 1 " fix folds reverting on every write due to go_fmt


"" Tabs and indenting
syntax on               " enable syntax highlighting
filetype on             " enable filetype detection
filetype indent on      " enable filetype-specific indenting
filetype plugin on      " enable filetype-specific plugins
autocmd Filetype php setlocal noexpandtab tabstop=4 shiftwidth=4
set autoindent          " auto indenting
set smartindent         " smart indenting
set expandtab           " spaces instead of tabs
set smarttab            " better backspace and tab functionality
set backspace=2         " more powerful backspacing
set shiftwidth=2        " front of line
set tabstop=2
set softtabstop=2       " midline, even if no text after (with smarttab)
let g:html_indent_inctags = "html,body,head,tbody" "indent includes for html


"" Bells
set vb t_vb=            " disable all error bells and flashing
"set noerrorbells       " turn off audio bell
"set visualbell         " but leave on a visual bell


"" Search
" Fuzzy finding (\t)
map <leader>t :FZF<CR>
set rtp+=~/.fzf "add fuzzy finding if installed with git
set rtp+=/usr/local/opt/fzf "or if installed with homebrew

set hlsearch            " highlighted search results
" map space to turn off search highlighting in normal mode
nnoremap <Space> :noh<cr><Space>
set showmatch           " show matching bracket
set smartcase           " ignore case unless UC in search

" ignore annoying obviously bad paths for matching
set wildignore+=*.o,*.obj,*.swp,.git,.svn,tmp,log,.sass-cache,public,coverage,tests,content,node_modules


"" Other
set nobackup            " don't create pointless backup files; Use VCS instead

"fix scrolling in iterm
set mouse=a
if has("mouse_sgr")
    set ttymouse=sgr
else
    set ttymouse=xterm2
end


"" Clipboard
" :version must have +clipboard. Use vim, not vi, on osx homebrew. vim 7.4+
set clipboard+=unnamed " allow yy, etc. to interact with OS X clipboard


"" Mappings

" easier window movement
nmap <leader>h :wincmd h<CR>
nmap <leader>j :wincmd j<CR>
nmap <leader>k :wincmd k<CR>
nmap <leader>l :wincmd l<CR>

"map <F2> :NERDTreeToggle<CR>


"" Remappings
"let mapleader= "," " change leader to something easier if desired
" auto insert close brackets
"inoremap {      {}<Left>
"inoremap {<CR>  {<CR>}<Esc>O
"inoremap {{     {
"inoremap {}     {}
