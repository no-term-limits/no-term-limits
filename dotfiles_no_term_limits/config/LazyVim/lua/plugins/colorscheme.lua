return {
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      -- Neovim 0.10.0 changed default colorscheme so revert back to that
      -- https://neovim.io/doc/user/news-0.10.html
      colorscheme = "vim",
      style = "",
    },
  },
}
