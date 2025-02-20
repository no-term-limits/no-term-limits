return {
  "ibhagwan/fzf-lua",
  keys = {
    { "<leader>j", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
  },
}
