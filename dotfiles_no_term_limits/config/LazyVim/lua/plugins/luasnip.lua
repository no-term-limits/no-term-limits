-- see also luasnip-related stuff in config/autocmds.lua
return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
      require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
    end,
  },
  opts = {
    history = true,
    delete_check_events = "TextChanged",
    update_events = "InsertLeave,TextChangedI",
  },
}
