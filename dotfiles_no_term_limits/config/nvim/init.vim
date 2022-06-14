set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" function! TellVimPlugThatWeAreInNeovim()
" endfunction
" command! TellVimPlugThatWeAreInNeovim call TellVimPlugThatWeAreInNeovim()

" not sure why this doesn't cause vim-plug to load the ones marked 'on':
" but read the comment in dotfiles_no_term_limits/vimrc.bundles.local
" and why this was replaced with CommandThatNeverFires.
" 'TellVimPlugThatWeAreInNeovim'
" TellVimPlugThatWeAreInNeovim

""""""""""""""""""""""""""""""""""""""""""""""""""""
" Completion configs: https://github.com/nvim-lua/completion-nvim
" commented out since completion was removed in favor of cmp
" Use <Tab> and <S-Tab> to navigate through popup menu
" inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Set completeopt to have a better completion experience
" set completeopt=menuone,noinsert,noselect

" Avoid showing extra message when using completion
" set shortmess+=c
" let g:completion_enable_auto_popup = 1
" autocmd BufEnter * lua require'completion'.on_attach()

""""""""""""""""""""""""""""""""""""""""""""""""""""

luafile ~/.no_term_limits_vimrc.lua
