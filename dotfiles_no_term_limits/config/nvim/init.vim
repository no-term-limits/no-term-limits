set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

function! TellVimPlugThatWeAreInNeovim()
endfunction
command! TellVimPlugThatWeAreInNeovim call TellVimPlugThatWeAreInNeovim()

" not sure why this doesn't cause vim-plug to load the ones marked 'on':
" 'TellVimPlugThatWeAreInNeovim'
" TellVimPlugThatWeAreInNeovim

" load nvim-only plugins on-demand in a way that actually works
call plug#load('nvim-lspconfig')
call plug#load('completion-nvim')

""""""""""""""""""""""""""""""""""""""""""""""""""""
" Completion configs: https://github.com/nvim-lua/completion-nvim
" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c
let g:completion_enable_auto_popup = 1
autocmd BufEnter * lua require'completion'.on_attach()

""""""""""""""""""""""""""""""""""""""""""""""""""""

luafile ~/.no_term_limits_vimrc.lua
