local plugin_config = {
  -- gsr (go surround replace)
  { import = "lazyvim.plugins.extras.coding.mini-surround" },

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
  table.insert(plugin_config, { import = "lazyvim.plugins.extras.ai.copilot" })
  table.insert(plugin_config, { import = "lazyvim.plugins.extras.ai.copilot-chat" })
end

return plugin_config
