local fmt = require("luasnip.extras.fmt").fmt

local function awesome_func(args, snip)
  vim.print(args)
  return args[1][1]
end

return {
  s("d", t("import pdb; pdb.set_trace()")),
  s("fa", t("from __future__ import annotations")),
  s(
    "cl",
    fmt(
      [[
  print(f"{}", {})
  ]],
      {
        -- i(1) is at nodes[1], i(2) at nodes[2].
        i(1, "value"),
        f(awesome_func, { 1 }),
      }
    )
  ),
  s(
    "ec",
    fmt(
      [[
class {}(Exception):
	pass

  ]],
      {
        i(1, "MyHotError"),
      }
    )
  ),
}
