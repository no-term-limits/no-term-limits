-- otherwise we get a message on startup:
-- https://www.reddit.com/r/neovim/comments/11iuona/nvimnotify_highlight_groups_startup_notification
return {
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
    },
  },
}
