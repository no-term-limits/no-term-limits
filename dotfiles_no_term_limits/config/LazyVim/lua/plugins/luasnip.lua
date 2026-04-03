-- see also luasnip-related stuff in config/autocmds.lua
return {
  "L3MON4D3/LuaSnip",
  config = function()
    require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
    -- the load is needed for the tabstops to load in real time
    require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
  end,
  opts = {
    history = true,
    delete_check_events = "TextChanged",
    update_events = "InsertLeave,TextChangedI",
  },
}
