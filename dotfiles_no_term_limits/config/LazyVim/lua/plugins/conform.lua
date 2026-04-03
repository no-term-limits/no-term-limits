return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      -- use extra args with shfmt. -i 2 says use two spaces. otherwise shfmt uses tabs.
      shfmt = {
        prepend_args = { "-i", "2" },
      },
      -- stylelua uses tabs by default as well, but it is configured for spaces in no-term/.stylelua.toml
    },
  },
}
