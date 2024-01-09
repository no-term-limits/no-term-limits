-- the TelescopeResultsDiffAdd (blue) is much more readable than the default (Visual)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "TelescopeResultsDiffAdd", bg = "none" })
  end,
})
