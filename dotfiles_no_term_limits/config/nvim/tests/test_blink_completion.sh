#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)
file=$(mktemp -t ntl-blink-completion-XXXX.txt)

cleanup() {
  rm -rf "$temp_home"
  rm -f "$file"
}
trap cleanup EXIT

printf 'alpha\nalpha\nal\n' >"$file"

output=$(run_headless_nvim "$temp_home" +"e $file" +'lua local cmp=require("blink.cmp"); vim.api.nvim_win_set_cursor(0,{3,2}); cmp.show({ providers = { "buffer" } }); local visible = vim.wait(5000, function() return cmp.is_visible() end, 100); local items = cmp.get_items() or {}; print("VISIBLE=" .. tostring(visible)); print("ITEMS=" .. #items); if #items > 0 then print("FIRST_LABEL=" .. tostring(items[1].label)) end' +"qall!")

assert_contains "$output" "VISIBLE=true"
assert_contains "$output" "ITEMS=1"
assert_contains "$output" "FIRST_LABEL=alpha"
