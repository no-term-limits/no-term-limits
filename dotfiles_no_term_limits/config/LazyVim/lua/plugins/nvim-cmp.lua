return {

	"hrsh7th/nvim-cmp",

	-- config = function()
	-- 	-- vim.opt.completeopt = { "menu", "menuone", "noselect" }
	-- 	vim.opt.completeopt = "menu,menuone,noselect"
	--
	opts = function(_, opts)
		local cmp = require("cmp")
		opts.preselect = cmp.PreselectMode.None
		opts.completion = { completeopt = "menu,menuone,noselect" }
		opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = "emoji" } }))
	end,
	--  opts = function()
	--    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
	-- -- end,
	-- 	local cmp = require("cmp")
	-- 	local defaults = require("cmp.config.default")()
	-- 	return {
	-- 		completion = {
	-- 			completeopt = "menu,menuone,noinsert",
	-- 		},
	-- 		snippet = {
	-- 			expand = function(args)
	-- 				require("luasnip").lsp_expand(args.body)
	-- 			end,
	-- 		},
	-- 		mapping = cmp.mapping.preset.insert({
	-- 			["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
	-- 			["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
	-- 			["<C-b>"] = cmp.mapping.scroll_docs(-4),
	-- 			["<C-f>"] = cmp.mapping.scroll_docs(4),
	-- 			["<C-Space>"] = cmp.mapping.complete(),
	-- 			["<C-e>"] = cmp.mapping.abort(),
	-- 			["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	-- 			["<S-CR>"] = cmp.mapping.confirm({
	-- 				behavior = cmp.ConfirmBehavior.Replace,
	-- 				select = true,
	-- 			}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	-- 			["<C-CR>"] = function(fallback)
	-- 				cmp.abort()
	-- 				fallback()
	-- 			end,
	-- 		}),
	-- 		sources = cmp.config.sources({
	-- 			{ name = "nvim_lsp" },
	-- 			{ name = "luasnip" },
	-- 			{ name = "path" },
	-- 		}, {
	-- 			{ name = "buffer" },
	-- 		}),
	-- 		formatting = {
	-- 			format = function(_, item)
	-- 				local icons = require("lazyvim.config").icons.kinds
	-- 				if icons[item.kind] then
	-- 					item.kind = icons[item.kind] .. item.kind
	-- 				end
	-- 				return item
	-- 			end,
	-- 		},
	-- 		experimental = {
	-- 			ghost_text = {
	-- 				hl_group = "CmpGhostText",
	-- 			},
	-- 		},
	-- 		sorting = defaults.sorting,
	-- 	}
	-- end,
}
