"""
" Run :PlugInstall after dropping this in place to install plugins with vim-plug
"""

set nocompatible              " be iMproved, required

"" nastily install vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible' "sensible vim defaults

" assorted plugins
Plug 'scrooloose/syntastic' " syntax checking for various filetypes
Plug 'altercation/vim-colors-solarized' " the best colorscheme
Plug 'tpope/vim-abolish' " case-smart substitution with :S///, among other things

"NVIM INCOMPATIBLE
if !has('nvim')
  Plug 'tpope/vim-fugitive' " git wrapper
  " autocomplete - https://github.com/ycm-core/YouCompleteMe/issues/1751
  " requires cmake, golang, etc
  function! BuildYCM(info)
    if a:info.status == 'installed' || a:info.force
      !./install.py --clang-completer --go-completer --ts-completer
    endif
  endfunction
  Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }


  "" Clipboard
  " :version must have +clipboard. Use vim, not vi, on osx homebrew. vim 7.4+
  "" Linux apt-get install vim-gtk; alias vi=vim
  set clipboard=autoselect,unnamedplus
  " allow yy, etc. to interact with OS X clipboard

  "fix scrolling in iterm
  set mouse=a
  if has("mouse_sgr")
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  end
endif
"END NVIM INCOMPATIBLE

"NVIM ONLY
if has('nvim')
  Plug 'github/copilot.vim'

  let g:copilot_filetypes = {
        \ 'yaml': v:true,
        \ }

  set mouse=a
  set clipboard=unnamedplus " autoselect waiting for https://github.com/neovim/neovim/issues/2325

  source ~/.vim/scripts/partial_accept.vim
endif
"END NVIM ONLY

"autoresize
autocmd VimResized * wincmd =

"typescript
autocmd BufNewFile,BufRead *.ts setlocal filetype=typescript
Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
" post install (yarn install | npm install) then load plugin only for editing supported files
Plug 'prettier/vim-prettier', {
  \ 'do': 'npm install',
  \ 'for': ['javascript', 'typescript', 'css'] }

"ruby
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'thoughtbot/vim-rspec', { 'for': 'ruby' }
Plug 'tpope/vim-bundler', { 'for': 'ruby' }

"golang
Plug 'fatih/vim-go', { 'for': 'go'}
Plug 'mdempsky/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh', 'for': 'go' }
let g:go_addtags_transform="camelcase" " json tags in camelCase instead of snake_case, required for kube
let g:go_fmt_command = "gopls" " faster than goimports
let g:go_use_language_server = 1
let g:go_language_server_auto = 1

"Plug 'jgdavey/tslime.vim' " send commands to tmux

" Folding, comments, and formatting plugins
" Plug 'avakhov/vim-yaml', { 'for': 'yaml' } " autoformat yaml
let g:syntastic_yaml_checkers = [ "yamllint" ] " pip package
let g:syntastic_quiet_messages = { "type": "style", "file:e": "yaml"  }
Plug 'tmhedberg/SimpylFold' "folding
Plug 'scrooloose/nerdcommenter' " Comment blocks: \c<space> to toggle
let g:NERDSpaceDelims = 1

" Markdown

" Enable spellcheck
" ]s for next word
" zg to add word to spellfile
" zx for suggestions
" :h spell
autocmd FileType markdown setlocal spell spelllang=en_us

Plug 'godlygeek/tabular', { 'for': 'markdown' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
let g:vim_markdown_new_list_item_indent = 0 " don't indent list items
let g:vim_markdown_folding_disabled=1 " disable markdown auto folding

"Plug 'nathanaelkane/vim-indent-guides' " shows indent guides in colors
let g:indent_guides_enable_on_vim_startup = 0 " Turn off indent guides

" Elixir
Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
Plug 'mattreduce/vim-mix', { 'for': 'elixir' }

" Terraform
" Plug 'hashivim/vim-terraform'

call plug#end()
" Regular config resumes here

" Colorscheme
" let g:solarized_termcolors=256 " mediocre colors - use if termcolors are terrible
if (has("termguicolors"))
  " term pallete must be solarized for this to look ok
  " set termguicolors "i prefer the plugin's solarized palette over gnome's
  let g:solarized_termtrans=1
  let g:foo=1
endif

" workaround for tmux https://github.com/tmux/tmux/pull/2343 - relies on gtk theme name
let s:bg = system('gsettings get org.gnome.desktop.interface gtk-theme | grep -iq dark && echo -n dark')
if s:bg == "dark"
  set background=dark
else
  "set background=dark "TODO force dark until installed numix
  set background=light
endif

colorscheme solarized
highlight CursorLineNr cterm=standout term=standout

"" File handling
set encoding=utf-8
autocmd CursorHold * checktime
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
set modeline " allow modelines to override things, typically filetype

"" Appearance
set cursorcolumn        " highlight the current column
set cursorline          " highlight the current line
set laststatus=2        " always show status line
set number              " show line numbers
set ruler               " show cursor position in status line
set scrolloff=5         " show at least 5 lines above/below
set showcmd             " show selection metadata
set showmode            " show INSERT, VISUAL, etc. mode
set splitright          " put splits to right with :vsp

" Wrapping
set wrap           " wrap long lines (on display)
set lbr            " break at a sensible character (on display)
"set textwidth=80   " actually break

" Folding
set foldmethod=syntax
set foldcolumn=0
set foldnestmax=1
"set foldlevelstart=20
let g:go_fmt_experimental = 1 " fix folds reverting on every write due to go_fmt


"" Tabs and indenting
Plug 'vim-scripts/Smart-Tabs' " Smart tabs - tabs at line start, spaces for variable alignment
"to use: :RetabIndent[!]
set listchars=tab:▻\ ,nbsp:␣,trail:•,extends:⟩,precedes:⟨
set list                " since we have sensible tab displays now

syntax on               " enable syntax highlighting
filetype on             " enable filetype detection
filetype indent on      " enable filetype-specific indenting
filetype plugin on      " enable filetype-specific plugins
autocmd Filetype php setlocal noexpandtab tabstop=4 shiftwidth=4
autocmd Filetype go setlocal nolist " gofmt takes care of any issues so let's make it pretty
set autoindent          " auto indenting
set smartindent         " smart indenting
set expandtab           " spaces instead of tabs " generally overridden
set smarttab            " better backspace and tab functionality
set backspace=2         " more powerful backspacing
set shiftwidth=2        " front of line
set tabstop=2
set softtabstop=2       " midline, even if no text after (with smarttab)
let g:html_indent_inctags = "html,body,head,tbody" "indent includes for html

"" Bells
set vb t_vb=            " disable all error bells and flashing

"" Search
" Fuzzy finding (\t)
map <leader>t :FZF<CR>
set rtp+=~/.fzf "add fuzzy finding if installed with git
set rtp+=/usr/local/opt/fzf "or if installed with homebrew

set hlsearch            " highlighted search results
" map space to turn off search highlighting in normal mode
nnoremap <Space> :noh<cr><Space>
set showmatch           " show matching bracket
set ignorecase
set smartcase           " ignore case unless UC in search

" ignore annoying obviously bad paths for matching
set wildignore+=*.o,*.obj,*.swp,.git,.svn,tmp,log,.sass-cache,public,coverage,tests,content,node_modules


"" Other
set nobackup            " don't create pointless backup files; Use VCS instead


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
