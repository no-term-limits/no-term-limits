return {
  "echasnovski/mini.pairs",
  opts = {
    mappings = {
      ["("] = { action = "open", pair = "()", neigh_pattern = ".[^%a()]" },
      ["{"] = { action = "open", pair = "{}", neigh_pattern = ".[^%a{}]" },
      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = '.[^%a"]', register = { cr = false } },
      ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '.[^%a`]', register = { cr = false } },

      -- we cannot get the pattern to match [ so just disable it
      ["["] = false,
      -- we need a pattern that can match surrounding for works like it's but we do not know how to do that
      ["'"] = false,
    },
  },
}
