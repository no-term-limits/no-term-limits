return {

  "hrsh7th/nvim-cmp",

  opts = function(_, opts)
    local cmp = require("cmp")
    opts.preselect = cmp.PreselectMode.None
    opts.completion = { completeopt = "menu,menuone,noselect" }
    opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = "emoji" } }))

    local luasnip = require("luasnip")
    local mapping = {
      -- Supertab for luasnip snippets
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          if luasnip.expandable() then
            luasnip.expand()
          else
            cmp.confirm({
              select = true,
            })
          end
        else
          fallback()
        end
      end),

      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.locally_jumpable(1) then
          luasnip.jump(1)
        else
          fallback()
        end
      end, { "i", "s" }),

      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }
    -- Merge with existing mappings
    opts.mapping = vim.tbl_extend("force", opts.mapping or {}, mapping)
  end,
}
