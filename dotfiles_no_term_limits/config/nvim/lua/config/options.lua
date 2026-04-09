-- Options configuration

-- Set leader key to space (must be set before plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local data_site = vim.fn.stdpath("data") .. "/site"
if not vim.o.runtimepath:find(vim.pesc(data_site), 1, false) then
  vim.opt.runtimepath:append(data_site)
end

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

-- case sensitive search
vim.o.ignorecase = false

-- basic sane defaults
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
