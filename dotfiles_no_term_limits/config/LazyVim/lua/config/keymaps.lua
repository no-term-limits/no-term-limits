vim.keymap.set(
  "n",
  "cp",
  [[:let @+ = expand("%:p")<CR>]],
  { desc = "copy file to clipboard", noremap = false, silent = false }
)

-- add "find [in] dir" keymap to find files in the directory of the current buffer with telescope
-- replaces these keymaps:
--   cnoremap %% <C-R>=expand('%:h').'/'<cr>
--   map <localleader>ew :e %%
local builtin = require("telescope.builtin")
local utils = require("telescope.utils")
vim.keymap.set("n", "<leader>fd", function()
  builtin.find_files({ cwd = utils.buffer_dir() })
end, { noremap = false, silent = false, desc = "Find Files (buffer dir)" })

vim.keymap.set("n", "<leader>se", function()
  builtin.grep_string()
end, { noremap = false, silent = false, desc = "Grep word under cursor" })
