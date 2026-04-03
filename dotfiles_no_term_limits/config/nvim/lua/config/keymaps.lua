-- Keymaps configuration

-- copy full file path to clipboard
vim.keymap.set(
  "n",
  "cp",
  [[:let @+ = expand("%:p")<CR>]],
  { desc = "copy file to clipboard", noremap = false, silent = false }
)

-- there is never a time when we want to save a visual selection
vim.cmd([[cabbrev <expr> w getcmdtype()==':' && getcmdline() == "'<,'>w" ? '<c-u>w' : 'w']])

-- Add import for term under cursor
function AddImportForTermUnderCursor()
  local fullFilePath = vim.fn.expand("%:p")
  local wordUnderCursor = vim.fn.expand("<cword>")
  local importExpressionToSearchFor = "import \\<" .. wordUnderCursor .. "\\>"

  if vim.fn.search(importExpressionToSearchFor, "nw") == 0 then
    local desiredImportExpression =
      vim.fn.trim(vim.fn.system("find_import_lines_for_term " .. fullFilePath .. " " .. wordUnderCursor))
    vim.print(vim.v.shell_error)
    if vim.v.shell_error > 0 then
      vim.cmd('echom "' .. desiredImportExpression .. '"')
    else
      local current_content = vim.fn.getline(1, "$")
      local insert_position = 1
      if current_content[1] and current_content[1]:match("from __future__ import annotations") then
        insert_position = 2
      end
      table.insert(current_content, insert_position, desiredImportExpression)
      vim.fn.setline(1, current_content)
      vim.cmd("normal j")
    end
  else
    vim.cmd('echom "import already exists"')
  end
end

vim.keymap.set("n", "<leader>ri", AddImportForTermUnderCursor, { noremap = false, silent = false, desc = "Add import" })

-- Open current code line in browser
function OpenCurrentCodeLineInBrowser()
  local line_number = vim.fn.line(".")
  local file_full_path = vim.fn.expand("%:p")
  vim.fn.execute("! git_open " .. file_full_path .. " " .. line_number)
end

vim.keymap.set("n", "<leader>rb", OpenCurrentCodeLineInBrowser, { noremap = true, silent = true, desc = "Run [open current code line in] browser" })

-- Copy file path to clipboard (relative)
vim.keymap.set("n", "<leader>rc", [[:let @+ = fnamemodify(expand("%"), ":~:.")<CR>]], { noremap = true, silent = true, desc = "Copy file path to clipboard. see also cp for full path." })

-- Tmux integration
_G.tmux_command = ""

function _G.set_tmux_command()
  _G.tmux_command = vim.fn.input("Enter command to run in tmux pane: ")
  if _G.tmux_command == "" then
    print("No command entered.")
  else
    print("Command set: " .. _G.tmux_command)
  end
end

function _G.run_tmux_command(pane)
  if _G.tmux_command ~= "" then
    local cmd = string.format("tmux send-keys -t %s '%s' C-m", pane, _G.tmux_command)
    os.execute(cmd)
  else
    print("No command set. Use :lua set_tmux_command() to set the command.")
  end
end

vim.api.nvim_set_keymap("n", "<leader>rs", [[:lua set_tmux_command()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>rr", [[:lua run_tmux_command("{right-of}")<CR>]], { noremap = true, silent = true })

function _G.run_tmux_command_on_save()
  if _G.tmux_command ~= "" then
    local cmd = string.format("tmux send-keys -t {right-of} '%s' C-m", _G.tmux_command)
    os.execute(cmd)
  end
end

vim.api.nvim_exec([[
  augroup RunTmuxCommandOnSave
      autocmd!
      autocmd BufWritePost * lua run_tmux_command_on_save()
  augroup END
]], false)

-- Python test function detection
function _G.get_current_python_function()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local current_node = ts_utils.get_node_at_cursor()
  if not current_node then return nil end

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

vim.api.nvim_set_keymap("n", "<leader>rt", [[:lua _G.set_poet_command()<CR>]], { noremap = true, silent = true })
