-- https://www.lazyvim.org/configuration/plugins#%EF%B8%8F-adding--disabling-plugin-keymaps
return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- ctrl+p goes way back
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  },
}
