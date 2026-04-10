#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)

cleanup() {
  rm -rf "$temp_home"
}
trap cleanup EXIT

output=$(run_headless_nvim "$temp_home" +'lua local keys = { "<leader>ri", "<leader>rf", "<leader>rc", "<leader>rs", "<leader>rr", "<leader>rt", "<C-h>", "<C-j>", "<C-k>", "<C-l>" }; for _, lhs in ipairs(keys) do local map = vim.fn.maparg(lhs, "n", false, true); print(lhs .. "=" .. tostring(next(map) ~= nil)) end; print("FILETOOLING_CMD=" .. tostring(vim.fn.exists(":FileTooling") == 2)); print("ZELLIJ_CMD=" .. tostring(vim.fn.exists(":ZellijNavigateLeftTab") == 2))' +"qall!")

assert_contains "$output" "<leader>ri=true"
assert_contains "$output" "<leader>rf=true"
assert_contains "$output" "<leader>rc=true"
assert_contains "$output" "<leader>rs=true"
assert_contains "$output" "<leader>rr=true"
assert_contains "$output" "<leader>rt=true"
assert_contains "$output" "<C-h>=true"
assert_contains "$output" "<C-j>=true"
assert_contains "$output" "<C-k>=true"
assert_contains "$output" "<C-l>=true"
assert_contains "$output" "FILETOOLING_CMD=true"
assert_contains "$output" "ZELLIJ_CMD=true"
