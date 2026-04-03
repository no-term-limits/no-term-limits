local fmt = require("luasnip.extras.fmt").fmt

local function getUseStateSetter(args, _snip)
  local firstValue = args[1][1]
  -- vim.print(firstValue)
  local firstLetter = firstValue:sub(1, 1)
  local capitalizedFirstLetter = string.upper(firstLetter)
  local restOfWord = firstValue:sub(2)
  return "set" .. capitalizedFirstLetter .. restOfWord
end

local console_log_snippet = {
  t('console.log("'),
  i(1, "value"),
  t('", '),
  extras.rep(1),
  t(")"),
}

-- this version does not have a type hint
-- local use_state_snippet = {
--   t("const ["),
--   i(1, "dataVar"),
--   t(", "),
--   f(getUseStateSetter, { 1 }),
--   t("] = useState("),
--   i(2, "defaultValue"),
--   t(")"),
-- }

local awesome_use_state_snippet_with_fmt = fmt(
  [[
  const [{}, {}] = useState<{}>({})
  ]],
  {
    i(1, "dataVar"),
    f(getUseStateSetter, { 1 }),
    i(2, "typeHint"),
    i(3, "defaultValue"),
  }
)

return {
  s("trig", t("also loaded!!")),
  s("cl", console_log_snippet),
  s("us", awesome_use_state_snippet_with_fmt),
}
