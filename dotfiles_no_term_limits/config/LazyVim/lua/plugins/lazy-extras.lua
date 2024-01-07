-- this is an override of part of the default lazyvim lua/config/lazy.lua, since i'd rather not fully override the file with a symlink to our repo.
-- the lazyvim extras (like lazyvim.plugins.extras.lang.typescript) actually do load like i intend. i hope it isn't double loading lazyvim.
return {
  { "LazyVim/LazyVim" },
  -- import any extras modules here
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.python" },

  { import = "lazyvim.plugins.extras.coding.copilot" },

  -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
}
