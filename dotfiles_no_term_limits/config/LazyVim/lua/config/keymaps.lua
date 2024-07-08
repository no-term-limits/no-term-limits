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
  local file_full_path = vim.fn.expand("%:p")
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

-- make this in lua instead of vimscript
-- nmap <leader>rc :let @+ = expand("%:h") . '/' . expand("%:t")<cr>:echo 'copied file path into clipboard. note that cp copies the full path'<cr>
vim.keymap.set(
  "n",
  "<leader>rc",
  [[:let @+ = fnamemodify(expand("%"), ":~:.")<CR>]],
  { noremap = true, silent = true, desc = "Copy file path to clipboard. see also cp for full path." }
)

-- Global variable to store the command
_G.tmux_command = ""

-- Function to set the command
function _G.set_tmux_command()
  _G.tmux_command = vim.fn.input("Enter command to run in tmux pane: ")
  if _G.tmux_command == "" then
    print("No command entered.")
  else
    print("Command set: " .. _G.tmux_command)
  end
end

-- Function to run the command in the specified tmux pane
function _G.run_tmux_command(pane)
  if _G.tmux_command ~= "" then
    local cmd = string.format("tmux send-keys -t %s '%s' C-m", pane, _G.tmux_command)
    os.execute(cmd)
  else
    print("No command set. Use :lua set_tmux_command() to set the command.")
  end
end

-- Map <leader>rs to set the command
vim.api.nvim_set_keymap("n", "<leader>rs", [[:lua set_tmux_command()<CR>]], { noremap = true, silent = true })

-- Map <leader>rr to run the command in the right tmux pane
vim.api.nvim_set_keymap(
  "n",
  "<leader>rr",
  [[:lua run_tmux_command("{right-of}")<CR>]],
  { noremap = true, silent = true }
)

-- Function to check if tmux_command is set and run it in tmux on save
function _G.run_tmux_command_on_save()
  if _G.tmux_command ~= "" then
    local cmd = string.format("tmux send-keys -t {right-of} '%s' C-m", _G.tmux_command)
    os.execute(cmd)
  end
end

-- Set autocmd to run run_tmux_command_on_save after saving a file if tmux_command is set
vim.api.nvim_exec(
  [[
    augroup RunTmuxCommandOnSave
        autocmd!
        autocmd BufWritePost * lua run_tmux_command_on_save()
    augroup END
]],
  false
)

-- Function to detect the current Python function using Treesitter
function _G.get_current_python_function()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local current_node = ts_utils.get_node_at_cursor()

  if not current_node then
    return nil
  end

  while current_node do
    if current_node:type() == "function_definition" then
      for child in current_node:iter_children() do
        if child:type() == "identifier" then
          return vim.treesitter.get_node_text(child, 0)
        end
      end
    end
    current_node = current_node:parent()
  end

  return nil
end

-- Function to set the command to "poet [function_name]" if it starts with "test_"
function _G.set_poet_command()
  local function_name = _G.get_current_python_function()
  if function_name then
    if function_name:match("^test_") then
      _G.tmux_command = "poet " .. function_name
      print("Command set: " .. _G.tmux_command)
    else
      print("Function '" .. function_name .. "' does not start with 'test_'. Command not set.")
    end
  else
    print("No Python function found at cursor position.")
  end
end

-- Map <leader>rt to set the poet command
vim.api.nvim_set_keymap("n", "<leader>rt", [[:lua _G.set_poet_command()<CR>]], { noremap = true, silent = true })
