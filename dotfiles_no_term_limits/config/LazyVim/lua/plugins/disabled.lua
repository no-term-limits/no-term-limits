return {
  -- this is the hammer, to disable flash, the thing enhances search by putting letters at the end of each match to let you jump to them
  -- we don't actually like coopting slash like this, so we disable it, but it's possible we also can't tolerate the overrides for f, etc.
  { "folke/flash.nvim", enabled = false },
  -- {
  --   "folke/flash.nvim",
  --   opts = {
  --     modes = {
  --       search = {
  --         enabled = false,
  --       },
  --     },
  --   },
  -- },
  -- we have our own, very small, snippet collection
  { "rafamadriz/friendly-snippets", enabled = false },
  { "folke/snacks.nvim", opts = { scroll = { enabled = false } } },

  -- get the full list of plugins to potentially disable using <leader>rp
}
