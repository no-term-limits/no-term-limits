-- this is an override of part of the default lazyvim lua/config/lazy.lua, since i'd rather not fully override the file with a symlink to our repo.
-- the lazyvim extras (like lazyvim.plugins.extras.lang.typescript) actually do load like i intend. i hope it isn't double loading lazyvim.

local plugin_config = {
  { "LazyVim/LazyVim" },

  -- LazyVim uses native neovim snippets now but our configs depend on luasnip
  { import = "lazyvim.plugins.extras.coding.luasnip" },

  -- everyday languages
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.python" },

  -- languages that are not as important, but why not
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.terraform" },

  -- linting
  { import = "lazyvim.plugins.extras.linting.eslint" },

  -- formatting
  { import = "lazyvim.plugins.extras.formatting.prettier" },
}

if os.getenv("NO_TERM_LIMITS_DISABLE_COPILOT") == nil then
  -- AI
  plugin_config.insert({ import = "lazyvim.plugins.extras.coding.copilot" })
end

return plugin_config
