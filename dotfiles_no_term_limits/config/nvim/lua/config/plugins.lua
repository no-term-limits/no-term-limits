-- Plugin configurations
-- All plugins are loaded from pack/plugins/start/ via native vim.pack

-- LSP Configuration
local lsp_ok, _ = pcall(require, "lspconfig")
if lsp_ok then
  -- Use new vim.lsp.config API for nvim 0.11+ to avoid deprecation warnings
  if vim.lsp.config then
    vim.lsp.config("*", {
      root_markers = { ".git", "pyproject.toml", "package.json" },
    })
    vim.lsp.enable({ "pyright", "ts_ls", "jsonls", "yamlls", "bashls" })
  else
    -- Fallback to old API for older nvim versions
    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({})
    lspconfig.ts_ls.setup({})
    lspconfig.jsonls.setup({})
    lspconfig.yamlls.setup({})
    lspconfig.bashls.setup({})
  end

  vim.diagnostic.config({
    virtual_text = { source = "always", prefix = "●" },
    float = { source = "always" },
  })
end

-- Treesitter Configuration
local ts_ok, treesitter = pcall(require, "nvim-treesitter.configs")
if ts_ok then
  treesitter.setup({
    ensure_installed = { "python", "javascript", "typescript", "tsx", "json", "yaml", "bash", "lua", "vim" },
    highlight = { enable = true },
    indent = { enable = true },
  })
end

-- Blink.cmp Configuration
local blink_ok, blink = pcall(require, "blink.cmp")
if blink_ok then
  blink.setup({
    snippets = { preset = "luasnip" },
    sources = { default = { "snippets", "lsp", "path", "buffer" } },
    keymap = {
      preset = "enter",
      ["<CR>"] = { "fallback" },
      ["<Tab>"] = { "select_and_accept" },
    },
  })
end

-- LuaSnip Configuration
local luasnip_ok, luasnip = pcall(require, "luasnip")
if luasnip_ok then
  require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
  require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
  luasnip.config.setup({
    history = true,
    delete_check_events = "TextChanged",
    update_events = "InsertLeave,TextChangedI",
  })
end

-- Conform.nvim Configuration (formatting)
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
  conform.setup({
    formatters_by_ft = {
      python = { "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      sh = { "shfmt" },
      lua = { "stylua" },
    },
    formatters = {
      shfmt = { prepend_args = { "-i", "2" } },
    },
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function(args)
      conform.format({ bufnr = args.buf })
    end,
  })
end

-- nvim-lint Configuration
local lint_ok, lint = pcall(require, "lint")
if lint_ok then
  lint.linters_by_ft = {
    python = { "mypy" },
    sh = { "shellcheck" },
  }

  lint.linters.mypy = {
    cmd = "run_mypy_with_poetry_for_lint",
    append_fname = true,
    condition = function(ctx)
      local pyproject = vim.fs.find({ "pyproject.toml" }, { path = ctx.filename, upward = true })[1]
      if pyproject then
        return vim.fn.match(vim.fn.readfile(pyproject), "mypy") >= 0
      end
      return false
    end,
  }

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    callback = function() lint.try_lint() end,
  })
end

-- telescope.nvim Configuration
local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
  telescope.setup({})
  local builtin = require("telescope.builtin")
  vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
  vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
end

-- text-case.nvim Configuration
local textcase_ok, textcase = pcall(require, "textcase")
if textcase_ok then
  textcase.setup({})
end

-- which-key.nvim Configuration
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
  wk.setup({
    delay = 500,
  })
end
