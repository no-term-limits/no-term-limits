-- https://www.lazyvim.org/configuration/plugins#%EF%B8%8F-adding--disabling-plugin-keymaps
return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      -- shell
      "shfmt",
      "shellcheck",
      -- python
      "mypy",
      -- for markdown/prose, LSP language server for LanguageTool
      "ltex-ls",
      -- misc
      "stylua",
      "json-lsp",
    },
  },
}
