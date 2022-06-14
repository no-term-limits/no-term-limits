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
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      -- { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

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

  local sources = {
        null_ls.builtins.diagnostics.shellcheck,

        null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.eslint,

        -- python
        null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.diagnostics.pydocstyle,

        -- these do not understand imports of stuff installed via poetry, so they have a bunch of false positives
        -- null_ls.builtins.diagnostics.mypy,
        -- null_ls.builtins.diagnostics.pylint,
        --
        -- run <leader>lf to format the current file
        null_ls.builtins.formatting.autopep8,
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.reorder_python_imports,

        null_ls.builtins.completion.spell,
    }

null_ls.setup({
    sources = sources,
})

  -- require("trouble").setup {
  --   -- your configuration comes here
  --   -- or leave it empty to use the default settings
  --   -- refer to the configuration section below
  -- }

-- local nvim_lsp = require('lspconfig')
--
-- local on_attach = function(client, bufnr)
--   local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
--   local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
--
--   buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
--
--   -- Mappings.
--   local opts = { noremap=true, silent=true }
--   buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
--   buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
--   buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
--   buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
--   buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
--   buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
--   buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
--   buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
--   buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
--   buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
--   buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
--   buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
--   buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
--   buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
--   buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
--
--   -- Set some keybinds conditional on server capabilities
--   if client.resolved_capabilities.document_formatting then
--     buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
--   elseif client.resolved_capabilities.document_range_formatting then
--     buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
--   end
--
--   -- Set autocommands conditional on server_capabilities
--   if client.resolved_capabilities.document_highlight then
--     vim.api.nvim_exec([[
--       hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
--       hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
--       hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
--       augroup lsp_document_highlight
--         autocmd! * <buffer>
--         autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
--         autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
--       augroup END
--     ]], false)
--   end
-- end
--
-- -- Use a loop to conveniently both setup defined servers 
-- -- and map buffer local keybindings when the language server attaches
-- local servers = { "solargraph", "tsserver", "pyright" }
-- for _, lsp in ipairs(servers) do
--   nvim_lsp[lsp].setup { on_attach = on_attach }
-- end
