-- Autocmds configuration

-- LuaSnip: forget snippet when leaving insert mode
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("UnlinkLuaSnipSnippetOnModeChange", { clear = true }),
  pattern = { "s:n", "i:*" },
  desc = "Forget the current snippet when leaving the insert mode",
  callback = function(evt)
    local ok, luasnip = pcall(require, "luasnip")
    if not ok then return end
    while true do
      if luasnip.session and luasnip.session.current_nodes[evt.buf] and not luasnip.session.jump_active then
        luasnip.unlink_current()
      else
        break
      end
    end
  end,
})

-- Mark script files with shebangs as executable on write
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function()
    local shebang = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]
    if not shebang or not shebang:match("^#!.+") then return end

    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function(args)
        local filename = vim.api.nvim_buf_get_name(args.buf)
        local fileinfo = vim.uv.fs_stat(filename)
        if not fileinfo or bit.band(fileinfo.mode - 32768, 0x40) ~= 0 then return end
        vim.uv.fs_chmod(filename, bit.bor(fileinfo.mode, 493))
      end,
      once = true,
    })
  end,
  desc = "Mark script files with shebangs as executable on write.",
})

-- Restore the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("RestoreCursorPosition", { clear = true }),
  callback = function(args)
    local last_line = vim.api.nvim_buf_line_count(args.buf)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local row = mark[1]
    local col = mark[2]

    if row <= 0 or row > last_line then
      return
    end

    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end,
  desc = "Restore cursor to the last known position when reopening a file.",
})
