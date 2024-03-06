local hot_schemas_to_inject = {
  ["https://raw.githubusercontent.com/datreeio/crds-catalog/main/argoproj.io/application_v1alpha1.json"] = "hot.yml",
}

local language_for_spelling = "en-US"

return {
  "neovim/nvim-lspconfig",
  opts = {
    -- options for vim.diagnostic.config()
    diagnostics = {
      virtual_text = {
        -- always show where the diagnostic message came from, rather than the default if_many, which only shows it if there are multiple
        source = "always",
        -- prefix = "●",
        -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
        -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
        prefix = "icons",
      },
    },
    setup = {
      ltex = function(_, opts)
        local path = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
        if vim.fn.filereadable(path) == 1 then
          for word in io.open(path, "r"):lines() do
            table.insert(opts.settings.ltex.dictionary[language_for_spelling], word)
          end
        end
      end,
    },
    servers = {
      ltex = {
        settings = {
          ltex = {
            language = language_for_spelling,
            dictionary = { [language_for_spelling] = {} },
          },
        },
      },
      yamlls = {
        -- yaml seems to work. hot.yml is validated.
        on_new_config = function(new_config)
          new_config.settings.yaml.schemas = vim.tbl_deep_extend(
            "force",
            new_config.settings.yaml.schemas or hot_schemas_to_inject,
            require("schemastore").yaml.schemas()
          )
        end,
      },
      -- json seems to NOT work. hot.json is not validated when line two is changed to hot.json, even though <leader>li shows vscode-json-language-server running. the print statements don't work in either yaml or json.
      jsonls = {
        on_new_config = function(new_config)
          new_config.settings.json.schemas = new_config.settings.json.schemas or hot_schemas_to_inject
          vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
        end,
      },
    },
  },
}
