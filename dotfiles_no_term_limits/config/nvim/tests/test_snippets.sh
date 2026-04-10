#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)
file=$(mktemp -t ntl-snippet-XXXX.py)

cleanup() {
  rm -rf "$temp_home"
  rm -f "$file"
}
trap cleanup EXIT

output=$(run_headless_nvim "$temp_home" +"e $file" +'lua vim.bo.filetype="python"; local ls=require("luasnip"); local target=nil; for _, snippet in ipairs(ls.get_snippets("python") or {}) do if snippet.trigger == "d" then target = snippet break end end; print("FOUND_SNIPPET=" .. tostring(target ~= nil)); if target then ls.snip_expand(target) end; print("LINE=" .. vim.api.nvim_get_current_line())' +"qall!")

assert_contains "$output" "FOUND_SNIPPET=true"
assert_contains "$output" "LINE=import pdb; pdb.set_trace()"
