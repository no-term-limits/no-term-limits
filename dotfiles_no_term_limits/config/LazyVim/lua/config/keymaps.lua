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

-- there is never a time when we want to save a visual selection: https://vi.stackexchange.com/a/16735
vim.cmd([[cabbrev <expr> w getcmdtype()==':' && getcmdline() == "'<,'>w" ? '<c-u>w' : 'w']])

--
function AddImportForTermUnderCursor()
  local fullFilePath = vim.fn.expand("%:p")
  local wordUnderCursor = vim.fn.expand("<cword>")

  local importExpressionToSearchFor = "import " .. wordUnderCursor

  -- Look in other files in the current project and find the import for the word under the cursor
  if vim.fn.search(importExpressionToSearchFor, "nw") == 0 then
    -- If the import isn't already there, add it
    -- vim.print(fullFilePath .. wordUnderCursor)
    local desiredImportExpression =
      vim.fn.trim(vim.fn.system("find_import_lines_for_term " .. fullFilePath .. " " .. wordUnderCursor))
    -- vim.print(desiredImportExpression)
    vim.print(vim.v.shell_error)
    if vim.v.shell_error > 0 then
      vim.cmd('echom "' .. desiredImportExpression .. '"')
    else
      -- add the string of text in desiredImportExpression to the top of the file using pure lua stuff without moving the cursor

      -- Get the current buffer content
      local current_content = vim.fn.getline(1, "$")

      -- Insert the Lua string at the beginning of the table
      table.insert(current_content, 1, desiredImportExpression)

      -- Set the modified content back to the buffer
      vim.fn.setline(1, current_content)

      -- Since an import line was added, go back to the place we were by going down one line, so that the cursor is again on top of the same character of the same term
      vim.cmd("normal j")
    end
  else
    vim.cmd('echom "import already exists"')
  end
end

vim.keymap.set("n", "<leader>ri", AddImportForTermUnderCursor, { noremap = false, silent = false, desc = "Add import" })

-- define LazyActiveLinters command to see what nvim-lint is up to
-- doesn't actually work, despite get_running() being documented on the nvim-lint github page
local lint_progress = function()
  local linters = require("lint").get_running()
  local active_linters = ""
  if #linters == 0 then
    active_linters = "none"
  else
    active_linters = "󱉶 " .. table.concat(linters, ", ")
  end
  vim.print("active linters: " .. active_linters)
end

vim.api.nvim_create_user_command("LazyActiveLinters", lint_progress, {})

function OpenCurrentCodeLineInBrowser()
  local line_number = vim.fn.line(".")
  local file_full_path = vim.fn.bufname()
  vim.fn.execute("! git_open " .. file_full_path .. " " .. line_number)
end

function DumpLazyPluginList()
  table_of_plugins = require("lazy").plugins()
  local keys = {}

  for k, plugin_spec_table in pairs(table_of_plugins) do
    for plugin_name, value_thing in pairs(plugin_spec_table) do
      if type(plugin_name) == "number" then
        if type(value_thing) == "string" then
          table.insert(keys, value_thing)
        end
      end
    end
  end
  local file = io.open("/tmp/lazy_plugins.txt", "w")
  if not file then
    vim.print("Failed to open file for writing")
    return
  end
  file:write(table.concat(keys, "\n"))
  vim.notify("Wrote lazy plugin list to /tmp/lazy_plugins.txt")
end

vim.keymap.set(
  "n",
  "<leader>rb",
  OpenCurrentCodeLineInBrowser,
  { noremap = true, silent = true, desc = "Run [open current code line in] browser" }
)
vim.keymap.set(
  "n",
  "<leader>rp",
  DumpLazyPluginList,
  { noremap = true, silent = true, desc = "Run print lazy plugin list" }
)
