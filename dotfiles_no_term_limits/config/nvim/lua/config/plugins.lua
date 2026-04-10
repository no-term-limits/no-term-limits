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
    vim.lsp.enable({ "pyright", "ts_ls", "jsonls", "yamlls", "bashls", "terraformls" })
  else
    -- Fallback to old API for older nvim versions
    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({})
    lspconfig.ts_ls.setup({})
    lspconfig.jsonls.setup({})
    lspconfig.yamlls.setup({})
    lspconfig.bashls.setup({})
    lspconfig.terraformls.setup({})
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
    ensure_installed = { "python", "javascript", "typescript", "tsx", "json", "yaml", "bash", "lua", "vim", "terraform", "hcl" },
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
      ["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_and_accept()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },
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
      python = { "ruff_format" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      terraform = { "terraform_fmt" },
      hcl = { "terraform_fmt" },
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
  local function project_mentions_mypy(filename)
    local pyproject = vim.fs.find({ "pyproject.toml" }, { path = filename, upward = true })[1]
    if not pyproject then
      return false
    end

    local file_contents = table.concat(vim.fn.readfile(pyproject), "\n")
    return file_contents:match("mypy") ~= nil
  end

  lint.linters_by_ft = {
    python = { "mypy" },
    sh = { "shellcheck" },
  }

  local default_mypy_linter = lint.linters.mypy
  if type(default_mypy_linter) == "function" then
    default_mypy_linter = default_mypy_linter()
  end

  lint.linters.mypy = vim.tbl_deep_extend("force", default_mypy_linter or {}, {
    cmd = "run_mypy_with_poetry_for_lint",
    append_fname = true,
    condition = function(ctx)
      return project_mentions_mypy(ctx.filename)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    callback = function() lint.try_lint() end,
  })
end

-- telescope.nvim Configuration
local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
  telescope.setup({
    pickers = {
      buffers = {
        previewer = false,
      },
      find_files = {
        previewer = false,
      },
    },
  })
  local builtin = require("telescope.builtin")
  vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
  vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Buffers" })
  vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
  vim.keymap.set("n", "<leader>ut", require("config.themes").picker, { desc = "Theme picker" })
end

-- text-case.nvim Configuration
local textcase_ok, textcase = pcall(require, "textcase")
if textcase_ok then
  textcase.setup({})
end

-- gitsigns.nvim Configuration
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
if gitsigns_ok then
  gitsigns.setup({
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Git reset hunk" })
      vim.keymap.set("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { buffer = bufnr, desc = "Git reset hunk" })
      vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Git preview hunk" })
      vim.keymap.set("n", "<leader>gb", function() gs.blame_line({ full = true }) end, { buffer = bufnr, desc = "Git blame line" })
      vim.keymap.set("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { buffer = bufnr, expr = true, desc = "Next git hunk" })
      vim.keymap.set("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { buffer = bufnr, expr = true, desc = "Prev git hunk" })
    end,
  })
end

-- which-key.nvim Configuration
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
  wk.setup({
    delay = 250,
  })
  -- Register leader key groups so they show up in menu
  wk.add({
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>r", group = "run" },
    { "<leader>u", group = "ui" },
  })
end

-- zellij-nav.nvim Configuration
local zellij_nav_ok, zellij_nav = pcall(require, "zellij-nav")
if zellij_nav_ok then
  zellij_nav.setup()
  vim.keymap.set("n", "<C-h>", "<cmd>ZellijNavigateLeftTab<CR>", { silent = true, desc = "Navigate left or tab" })
  vim.keymap.set("n", "<C-j>", "<cmd>ZellijNavigateDown<CR>", { silent = true, desc = "Navigate down" })
  vim.keymap.set("n", "<C-k>", "<cmd>ZellijNavigateUp<CR>", { silent = true, desc = "Navigate up" })
  vim.keymap.set("n", "<C-l>", "<cmd>ZellijNavigateRightTab<CR>", { silent = true, desc = "Navigate right or tab" })
end
