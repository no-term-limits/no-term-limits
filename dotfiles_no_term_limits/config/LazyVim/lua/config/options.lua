-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- turn off vim mouse support
vim.opt.mouse = ""

-- swapfiles are mega annoying
vim.opt.swapfile = false.

-- turn off unnamedplus clipboard, since we don't want the main register syncing with system clipboard
vim.opt.clipboard = ""
