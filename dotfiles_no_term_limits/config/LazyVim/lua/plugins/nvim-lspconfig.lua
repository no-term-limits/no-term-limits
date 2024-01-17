return {
  "neovim/nvim-lspconfig",
  opts = {
    -- options for vim.diagnostic.config()
    diagnostics = {
      virtual_text = {
        -- always show where the diagnostic message came from, rather than the default if_many, which only shows it if there are multiple
        source = "always",
        -- prefix = "●",
        -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
        -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
        prefix = "icons",
      },
    },
  },
}
