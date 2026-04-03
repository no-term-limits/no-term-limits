return {
  "saghen/blink.cmp",
  dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
  opts = {
    snippets = { preset = "luasnip" },
    -- ensure you have the `snippets` source (enabled by default)
    sources = {
      default = { "snippets", "lsp", "path", "buffer" },
    },
    keymap = {
      preset = "enter",
      ["<CR>"] = { "fallback" },
      ["<Tab>"] = { "select_and_accept" },
    },
  },
}
