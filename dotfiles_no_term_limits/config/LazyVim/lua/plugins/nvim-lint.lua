return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      python = { "mypy" },
      sh = { "shellcheck" },
    },
    linters = {
      shellcheck = {
        append_fname = true,
      },
      mypy = {
        -- otherwise it won't be able to access the mypy extensions we require
        cmd = "run_mypy_with_poetry_for_lint",
        -- otherwise the command fails, since mpyp needs an argument. it's also slow if you just give it .
        append_fname = true,
        -- use mypy only when a pyproject.toml file is present that includes mypy
        condition = function(ctx)
          local pyproject_file = vim.fs.find({ "pyproject.toml" }, { path = ctx.filename, upward = true })[1]
          -- check if file contains the text "mypy"
          if pyproject_file then
            local file_contents = vim.fn.readfile(pyproject_file)
            local contains_mypy = vim.fn.match(file_contents, "mypy") >= 0
            return contains_mypy
          end
          return false
        end,
      },
    },
  },
}
