-- the TelescopeResultsDiffAdd (blue) is much more readable than the default (Visual)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- vim.api.nvim_set_hl(0, "TelescopeSelection", { link = "TelescopeResultsDiffAdd", bg = "none" })
    -- vim.api.nvim_set_hl(0, "TelescopePreviewLine", { link = "TelescopeResultsDiffAdd", bg = "none" })
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

-- Map the function to a key for convenience
vim.api.nvim_set_keymap(
  "n",
  "<leader>cc",
  ":lua print(vim.inspect(require('cmp').get_config().sources))<CR>",
  { noremap = true, silent = true }
)

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function()
    local shebang = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]

    if not shebang or not shebang:match("^#!.+") then
      return
    end

    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function(args)
        local filename = vim.api.nvim_buf_get_name(args.buf)

        local fileinfo = vim.uv.fs_stat(filename)

        if not fileinfo or bit.band(fileinfo.mode - 32768, 0x40) ~= 0 then
          return
        end

        vim.uv.fs_chmod(filename, bit.bor(fileinfo.mode, 493))
      end,
      once = true,
    })
  end,
  desc = "Mark script files with shebangs as executable on write.",
})
