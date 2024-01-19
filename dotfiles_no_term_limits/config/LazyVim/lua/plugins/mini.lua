return {
  "echasnovski/mini.pairs",
  enabled = false,
  -- opts = {
  --   mappings = {
  --     -- neigh_pattern, according to the "docs," is a two "character"
  --     -- pattern used to decide if it should insert the closing character.
  --     -- so for single quote, for example, when we say [^%w'][^%w'],
  --     -- that means if there is not a [^%w'] before it (a word character)
  --     -- or after it, insert a closing single quote.
  --     -- In order to escape certain characters like [ use % instead of \.
  --     ["("] = { action = "open", pair = "()", neigh_pattern = ".[^%w()]" },
  --     ["{"] = { action = "open", pair = "{}", neigh_pattern = ".[^%w{}]" },
  --     ['"'] = { action = "closeopen", pair = '""', neigh_pattern = '.[^%w"]', register = { cr = false } },
  --     ["`"] = { action = "closeopen", pair = "``", neigh_pattern = ".[^%w`]", register = { cr = false } },
  --     ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w'][^%w']", register = { cr = false } },
  --     ["["] = { action = "open", pair = "[]", neigh_pattern = ".[^%w%[%]]", register = { cr = false } },
  --   },
  -- },
}
