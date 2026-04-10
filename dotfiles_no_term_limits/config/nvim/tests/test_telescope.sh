#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)

cleanup() {
  rm -rf "$temp_home"
}
trap cleanup EXIT

output=$(run_headless_nvim "$temp_home" +'lua local builtin=require("telescope.builtin"); builtin.find_files({ cwd = vim.fn.getcwd() }); local ok=vim.wait(5000, function() return vim.bo.filetype == "TelescopePrompt" or #vim.api.nvim_list_wins() > 1 end, 50); print("PROMPT_OPEN=" .. tostring(ok)); print("FILETYPE=" .. vim.bo.filetype); print("WINDOWS=" .. #vim.api.nvim_list_wins())' +"qall!")

assert_contains "$output" "PROMPT_OPEN=true"
assert_contains "$output" "FILETYPE=TelescopePrompt"
assert_matches "$output" 'WINDOWS=[2-9][0-9]*|WINDOWS=[2-9]'
