for _, neovim_plugin_to_load in pairs(vim.g["neovim_plugins_ftw"]) do
  -- for example, when we get the repo without the org, neovim/nvim-lspconfig becomes nvim-lspconfig
  repo_without_org = neovim_plugin_to_load:match("/(.*)")
  vim.call('plug#load', repo_without_org)
end

if (vim.g.ntl_ultisnips_enabled == nil or vim.g.ntl_ultisnips_enabled ~= 0) then
  require("cmp_nvim_ultisnips").setup{}
  local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")
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

    -- otherwise Tab will not move through ultisnips placeholders.
    -- Tab is awesome for snippets but it breaks copilot.
    -- Just use ctrl+j the way you do to invoke the snippet in the first place.
    -- ["<Tab>"] = cmp.mapping(
    --   function(fallback)
    --     cmp_ultisnips_mappings.expand_or_jump_forwards(fallback)
    --   end,
    --   { "i", "s", --[[ "c" (to enable the mapping in command mode) ]] }
    -- ),
    --
    --
    ["<S-Tab>"] = cmp.mapping(
      function(fallback)
        cmp_ultisnips_mappings.jump_backwards(fallback)
      end,
      { "i", "s", --[[ "c" (to enable the mapping in command mode) ]] }
    ),
  }),
  sources = cmp.config.sources({
    { name = 'ultisnips' }, -- For ultisnips users.
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
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
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
local on_attach = function(client, bufnr)
  -- in nvim, i ran:
  --   :lua =vim.lsp.get_active_clients()[1].server_capabilities
  -- where lua =vim.lsp.get_active_clients()[1].name is pyright
  -- and got rid of all of its capabilities to try to get rid of these errors like this:
  --   Pyright: Import "flask" could not be resolved
  -- by setting their values to false like this:
  -- client.server_capabilities.renameProvider = false
  -- that did not work. instead, you need to fix the load path by creating a pyrightconfig.json with venv and venvPath (which is what i did)
  -- or disable the pyright rule with this configuration:
  --   https://github.com/microsoft/pyright/blob/main/docs/configuration.md#type-check-diagnostics-settings
  --   the rule in question is reportMissingModuleSource or reportMissingImports or something
  --
  -- client.server_capabilities.codeActionProvider = false
  -- client.server_capabilities.completionProvider = false
  -- client.server_capabilities.documentSymbolProvider = false
  -- client.server_capabilities.executeCommandProvider = false
  -- client.server_capabilities.renameProvider = false
  -- client.server_capabilities.textDocumentSync = false
  -- client.server_capabilities.workspace = false
  -- client.server_capabilities.typeDefinitionProvider = false
  -- client.server_capabilities.workspaceSymbolProvider = false

  -- client.server_capabilities.hoverProvider = false
  -- client.server_capabilities.documentHighlightProvider = false
  -- client.server_capabilities.declarationProvider = false
  -- client.server_capabilities.definitionProvider = false
  -- client.server_capabilities.referencesProvider = false
  -- client.server_capabilities.signatureHelpProvider = false
end

-- turns off all hints, since ruff already has those taken care of
-- https://www.reddit.com/r/neovim/comments/11k5but/comment/jbjwwtf
lspconfig['pyright'].setup {
  capabilities = (function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.publishDiagnostics.tagSupport.valueSet = { 2 }
    return capabilities
  end)()
}

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)

  -- we use <ctrl>k to navigate tmux and vim panes (go to pane above)
  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)

  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)

  -- we use <leader>f for fuzzy find
  -- vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

-- Configure `ruff-lsp`.
-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#ruff_lsp
-- For the default config, along with instructions on how to customize the settings
require('lspconfig').ruff_lsp.setup {
  on_attach = on_attach
}

-- allows for:
--   lua vim.lsp.buf.range_code_action() -- though it's deprecated and gone in neovim 9 and the replacement, vim.lsp.buf.code_action, doesn't work with this
--   lua vim.lsp.buf.rename()
-- pip install python-lsp-server
-- pip install pylsp-rope
-- lspconfig.pylsp.setup
--   settings = {
--     pylsp = {
--       plugins = {
--         pycodestyle = {
--           ignore = {'W391'},
--           maxLineLength = 100
--         }
--       }
--     }
--   }
-- }

require("typescript").setup({
    disable_commands = false, -- prevent the plugin from creating Vim commands
    debug = false, -- enable debug logging for commands
    server = { -- pass options to lspconfig's setup method
        on_attach = function(client)
        -- at least 0.8, https://www.reddit.com/r/neovim/comments/qskg6z/how_to_determine_whether_the_current_nvim_version/
        if vim.fn.has('nvim-0.8') == 1 then
          client.server_capabilities.documentFormattingProvider = false
        else
          client.resolved_capabilities.document_formatting = false
        end
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

nodejs_program_for_github_copilot = os.getenv("HOME") .. "/.asdf/installs/nodejs/16.16.0/bin/node"
if file_exists(nodejs_program_for_github_copilot) then
  vim.g["copilot_node_command"] = nodejs_program_for_github_copilot
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
  -- null_ls.builtins.diagnostics.flake8,
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
                -- on 0.8 and above, you should use vim.lsp.buf.format({ bufnr = bufnr })
                if vim.bo.filetype == "javascript" or vim.bo.filetype == "typescriptreact" or vim.bo.filetype == "typescript" then
                  if vim.fn.has('nvim-0.8') == 1 then
                    vim.lsp.buf.format({ bufnr = bufnr })
                  else
                    vim.lsp.buf.formatting_sync()
                  end
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

require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "python", "lua", "javascript" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  -- List of parsers to ignore installing (for "all")
  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- disable = { "c", "rust" },

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        -- you can optionally set descriptions to the mappings (used in the desc parameter of nvim_buf_set_keymap
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
      },
      -- You can choose the select mode (default is charwise 'v')
      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'V', -- linewise
        ['@class.outer'] = '<c-v>', -- blockwise
      },
      -- If you set this to `true` (default is `false`) then any textobject is
      -- extended to include preceding xor succeeding whitespace. Succeeding
      -- whitespace has priority in order to act similarly to eg the built-in
      -- `ap`.
      include_surrounding_whitespace = true,
    },
  },
}

-- Highlight the @foo.bar capture group with the "Identifier" highlight group
vim.api.nvim_set_hl(0, "@variable.python", { link = "Text" })

vim.api.nvim_create_autocmd('BufRead', {
  desc = 'turn on autowrap for markdown files if they already have lines longer than 100 characters',

  group = vim.api.nvim_create_augroup('no markdown autowrap', { clear = true }),
  callback = function (opts)
    if vim.bo[opts.buf].filetype == 'markdown' then
      -- iterate over all lines in file and see if it contains any lines with more than 80 characters.
      -- if so, turn off autowrap to match the style, which might be ventilated prose.
      longest_line = 0
      for ii, line_contents in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do
        if string.len(line_contents) > longest_line then
          longest_line = string.len(line_contents)
        end
      end
      if longest_line > 100 then
        -- https://stackoverflow.com/a/25687631/6090676
        vim.cmd 'setlocal formatoptions-=t'
      end
    end
  end,
})
