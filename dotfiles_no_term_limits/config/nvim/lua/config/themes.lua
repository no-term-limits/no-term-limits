local M = {}

M.repo_default = "vim"

M.themes = {
  { name = "tokyonight-night", label = "Tokyo Night" },
  { name = "kanagawa-wave", label = "Kanagawa Wave" },
  { name = "rose-pine", label = "Rose Pine" },
  { name = "catppuccin-macchiato", label = "Catppuccin Macchiato" },
  { name = "default", label = "Neovim Default" },
  { name = "vim", label = "Builtin Vim" },
}

local function get_local_config()
  local ok, local_config = pcall(require, "config.local")
  if ok and type(local_config) == "table" then
    return local_config
  end

  return {}
end

function M.get_default_theme()
  local local_config = get_local_config()
  return local_config.colorscheme or local_config.theme or M.repo_default
end

function M.apply(name)
  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("Failed to load colorscheme '" .. name .. "': " .. err, vim.log.levels.WARN)
    return false
  end

  return true
end

function M.apply_default()
  if M.apply(M.get_default_theme()) then
    return
  end

  vim.cmd.colorscheme("vim")
end

function M.picker()
  local telescope_ok, pickers = pcall(require, "telescope.pickers")
  if not telescope_ok then
    vim.notify("Telescope is not available", vim.log.levels.WARN)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Themes",
    finder = finders.new_table({
      results = M.themes,
      entry_maker = function(theme)
        return {
          value = theme,
          display = theme.label .. " [" .. theme.name .. "]",
          ordinal = theme.label .. " " .. theme.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value then
          M.apply(selection.value.name)
        end
      end)

      return true
    end,
  }):find()
end

return M
