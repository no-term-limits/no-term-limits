-- the TelescopeResultsDiffAdd (blue) is much more readable than the default (Visual)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "TelescopeResultsDiffAdd", bg = "none" })
    vim.api.nvim_set_hl(0, "TelescopePreviewLine", { link = "TelescopeResultsDiffAdd", bg = "none" })
    -- otherwise the cursor is invisible in command mode
    vim.api.nvim_set_hl(0, "NoiceCursor", { fg = "none", bg = "#ffffff" })
  end,
})

local luasnip = require("luasnip")

-- if you are in the middle of a snippet and leave insert mode, we want to forget about the snippet forever
-- https://github.com/L3MON4D3/LuaSnip/issues/656#issuecomment-1500869758
-- https://github.com/L3MON4D3/LuaSnip/issues/258#issuecomment-1429989436
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("UnlinkLuaSnipSnippetOnModeChange", {
    clear = true,
  }),
  pattern = { "s:n", "i:*" },
  desc = "Forget the current snippet when leaving the insert mode",
  callback = function(evt)
    -- If we have n active nodes, n - 1 will still remain after a `unlink_current()` call.
    -- We unlink all of them by wrapping the calls in a loop.
    while true do
      if luasnip.session and luasnip.session.current_nodes[evt.buf] and not luasnip.session.jump_active then
        luasnip.unlink_current()
      else
        break
      end
    end
  end,
})
