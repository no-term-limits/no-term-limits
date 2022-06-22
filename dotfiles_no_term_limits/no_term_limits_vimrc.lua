for _, neovim_plugin_to_load in pairs(vim.g["neovim_plugins_ftw"]) do
  -- neovim/nvim-lspconfig becomes nvim-lspconfig
  repo_without_org = neovim_plugin_to_load:match("/(.*)")
  vim.call('plug#load', repo_without_org)
end

local cmp = require'cmp'

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'ultisnips' }, -- For ultisnips users.
    { name = 'nvim_lsp' },
    { name = 'buffer' }, -- For autocompleting stuff from the current buffer
    { name = 'path' }, -- nvim-cmp source for filesystem paths.
  }, {
  })
})

-- https://github.com/onsails/lspkind.nvim/issues/19#issuecomment-915810181
-- lspkind icons didn't work for me out of the box and nobody has time for that.
-- this extends the nvim-cmp autocomplete menu to also show where each autocomplete
-- item comes from (LSP or Ultisnips or the current buffer, etc.
cmp.setup {
  formatting = {
    deprecated = true,
    format = function(entry, vim_item)
      -- set a name for each source
      vim_item.menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        ultisnips = "[Ultisnips]",
        nvim_lua = "[Lua]",
      })[entry.source.name]
      return vim_item
    end,
  },
}

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
require('lspconfig')['pyright'].setup {
  capabilities = capabilities
}

vim.lsp.handlers.hover = function() end

function file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

-- we don't seem to need python 2 any longer
-- python2_program = os.getenv("HOME") .. "/python2_neovim_virtual_env/bin/python"
-- if file_exists(python2_program) then
--   vim.g["python_host_prog"] = python2_program
-- end

python3_program = os.getenv("HOME") .. "/python3_neovim_virtual_env/bin/python"
if file_exists(python3_program) then
  vim.g["python3_host_prog"] = python3_program
end

-- disable ale augroup from thoughtbot/dotfiles
vim.api.nvim_exec([[
  autocmd! ale

  " mfussenegger/nvim-lint config
  " NOTE: you have to actually save the file j
  " au BufWritePost <buffer> lua require('lint').try_lint()
]], false)

-- mfussenegger/nvim-lint config. mypy and pylint didn't work, and i'm pretty sure they didn't work in ale either, which nvim-lint was an attempt to replace.
-- null-ls is an alternative solution for diagnostics / ale-like behavior
-- require('lint').linters_by_ft = {
--   -- " flake8', 'mypy', 'pylint', 'pyright'
--   python = {'flake8',}
-- }

local null_ls = require("null-ls")

local null_ls_sources = {
  null_ls.builtins.diagnostics.shellcheck,

  null_ls.builtins.formatting.stylua,
  null_ls.builtins.diagnostics.eslint,

  -- python
  null_ls.builtins.diagnostics.flake8,
  -- null_ls.builtins.diagnostics.pydocstyle,

  -- these did not understand imports of stuff installed via poetry (before run_mypy_with_poetry_for_null_ls), so they had a bunch of false positives
  -- still haven't fixed pylint
  null_ls.builtins.diagnostics.mypy.with({
    command = "run_mypy_with_poetry_for_null_ls",
  }),
  -- null_ls.builtins.diagnostics.pylint,
  --
  -- run <leader>lf to format the current file
  null_ls.builtins.formatting.autopep8,
  null_ls.builtins.formatting.black,
  null_ls.builtins.formatting.reorder_python_imports,

  null_ls.builtins.completion.spell,
}

null_ls.setup({
  sources = null_ls_sources,
})
