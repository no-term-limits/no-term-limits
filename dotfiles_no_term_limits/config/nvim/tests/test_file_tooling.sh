#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)
file=$(mktemp -t ntl-file-tooling-XXXX.py)

cleanup() {
  rm -rf "$temp_home"
  rm -f "$file"
}
trap cleanup EXIT

printf 'x = 1\n' >"$file"

output=$(run_headless_nvim "$temp_home" +"e $file" +FileTooling +'lua print("BUFNAME=" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")); print(table.concat(vim.api.nvim_buf_get_lines(0, 0, 18, false), "\n"))' +"qall!")

assert_contains "$output" "BUFNAME=File Tooling"
assert_contains "$output" "# File Tooling"
assert_contains "$output" "## LSP"
assert_contains "$output" "## Treesitter"
assert_contains "$output" "## Formatting"
assert_contains "$output" "## Linting"
