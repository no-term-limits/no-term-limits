for _, neovim_plugin_to_load in pairs(vim.g["neovim_plugins_ftw"]) do
  -- neovim/nvim-lspconfig becomes nvim-lspconfig
  repo_without_org = neovim_plugin_to_load:match("/(.*)")
  vim.call('plug#load', repo_without_org)
end

local cmp = require'cmp'

cmp.setup({
  -- debounce defaulted to 80 and throttle to 40 july 2022.
  -- https://github.com/hrsh7th/nvim-cmp/issues/598
  performance = {
    debounce = 400,
    throttle = 400
  },
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
    -- Set `select` to `false` to only confirm explicitly selected items. `true` is autocomplete with word at top of menu automatically.
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = 'ultisnips' }, -- For ultisnips users.
    { name = 'nvim_lsp' },
    { 
      -- For autocompleting stuff from the current buffer
      name = 'buffer',
      keyword_length = 3, -- only show autocompletions after i have typed 3 characters
      max_item_count = 5, -- maximium number of buffer results to display
      option = {
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end
      }
    }, 
    { name = 'path', keyword_length = 3 }, -- nvim-cmp source for filesystem paths.
  }, {
  }),

  -- https://github.com/onsails/lspkind.nvim/issues/19#issuecomment-915810181
  -- lspkind icons didn't work for me out of the box and nobody has time for that.
  -- this extends the nvim-cmp autocomplete menu to also show where each autocomplete
  -- item comes from (LSP or Ultisnips or the current buffer, etc.
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
-- we didn't like using buffer for '/'
-- cmp.setup.cmdline('/', {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = 'buffer' }
--   }
-- })

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
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
lspconfig['pyright'].setup {
  capabilities = capabilities
}

require("typescript").setup({
    disable_commands = false, -- prevent the plugin from creating Vim commands
    debug = false, -- enable debug logging for commands
    server = { -- pass options to lspconfig's setup method
        on_attach = function(client)
        client.resolved_capabilities.document_formatting = false
    end,
    },
})

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

-- Show the source
vim.diagnostic.config({
  virtual_text = {
    -- source = "if_many" -- might also be cool, but for now, it's really nice to know where the errors are coming from
    source = true
  }
})

-- diagnostics show errors
-- formatting codemods stuff
-- code actions, in here, are just for ignoring linting rules for the current line
local null_ls_sources = {
  -- shell
  null_ls.builtins.diagnostics.shellcheck,
  null_ls.builtins.code_actions.shellcheck,

  -- javascript
  null_ls.builtins.diagnostics.eslint_d, -- it's pretty funny that the eslint_d dianostics work fine without a custom command, but not formatting
  null_ls.builtins.formatting.eslint_d.with({
    command = "./node_modules/.bin/eslint_d",
  }),
  null_ls.builtins.code_actions.eslint_d,

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

  -- other
  null_ls.builtins.formatting.stylua,
  null_ls.builtins.completion.spell,
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

-- format on save with null_ls for javascript buffers
null_ls.setup({
  sources = null_ls_sources,
    -- you can reuse a shared lspconfig on_attach callback here
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                -- vim.lsp.buf.format({ bufnr = bufnr })
                if vim.bo.filetype == "javascript" or vim.bo.filetype == "typescriptreact" or vim.bo.filetype == "typescript" then
                  vim.lsp.buf.formatting_sync()
                end
            end,
        })
    end
  end,
})

function filter(arr, func)
	-- Filter in place
	-- https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
	local new_index = 1
	local size_orig = #arr
	for old_index, v in ipairs(arr) do
		if func(v, old_index) then
			arr[new_index] = v
			new_index = new_index + 1
		end
	end
	for i = new_index, size_orig do arr[i] = nil end
end


function filter_diagnostics(diagnostic)
	-- Only filter out Pyright stuff for now
	if diagnostic.source ~= "Pyright" then
		return true
	end

	-- Allow kwargs to be unused, sometimes you want many functions to take the
	-- same arguments but you don't use all the arguments in all the functions,
	-- so kwargs is used to suck up all the extras
	if diagnostic.message == '"kwargs" is not accessed' then
		return false
	end

	-- Allow variables starting with an underscore
	if string.match(diagnostic.message, '"_.+" is not accessed') then
		return false
	end

	return true
end

function custom_on_publish_diagnostics(a, params, client_id, c, config)
	filter(params.diagnostics, filter_diagnostics)
	vim.lsp.diagnostic.on_publish_diagnostics(a, params, client_id, c, config)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	custom_on_publish_diagnostics, {})
