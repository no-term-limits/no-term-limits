-- https://www.lazyvim.org/configuration/plugins#%EF%B8%8F-adding--disabling-plugin-keymaps
local builtin = require("telescope.builtin")
return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- ctrl+p goes way back
    {
      "<C-p>",
      function()
        builtin.find_files({ hidden = true, previewer = false })
      end,
      { noremap = false, silent = false, desc = "Find Files" },
    },
  },
}
