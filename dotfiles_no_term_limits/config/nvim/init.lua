-- No Term Limits Neovim Configuration
-- Using native pack/* plugin management with version pinning

-- Load options first
require("config.options")

vim.cmd.colorscheme("vim")

-- Load keymaps
require("config.keymaps")

-- Load autocmds
require("config.autocmds")

-- Load plugin configurations
require("config.plugins")
