-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- turn off vim mouse support
vim.opt.mouse = ""

-- swapfiles are mega annoying
vim.opt.swapfile = false

-- turn off unnamedplus clipboard, since we don't want the main register syncing with system clipboard
vim.opt.clipboard = ""

-- do not highlight full line
vim.o.cursorline = false

-- this is super annoying for pairing
vim.o.relativenumber = false

-- disable so json files will show quotes
vim.opt.conceallevel = 0

-- disable persistent undo
vim.o.undofile = false
