local fmt = require("luasnip.extras.fmt").fmt

local function awesome_func(args, snip)
	vim.print(args)
	return args[1][1]
end

return {
	s("trig", t("also loaded!!")),
	s("cl", {
		t('console.log("'),
		i(1, "value"),
		t('", '),
		extras.rep(1),
		t(")"),
	}),
	s(
		"cl2",
		fmt(
			[[
  console.log("{}", {})
  ]],
			{
				-- i(1) is at nodes[1], i(2) at nodes[2].
				i(1, "value"),
				f(awesome_func, { 1 }),
			}
		)
	),
}
