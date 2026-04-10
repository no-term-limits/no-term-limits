#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)
file=$(mktemp -t ntl-format-XXXX.py)

cleanup() {
  rm -rf "$temp_home"
  rm -f "$file"
}
trap cleanup EXIT

printf 'x=1\n' >"$file"

availability=$(run_headless_nvim "$temp_home" +"e $file" +'lua local conform=require("conform"); local names=conform.list_formatters_for_buffer(0); print("DECLARED=" .. table.concat(names, ",")); local formatter=conform.get_formatter_info("ruff_format", 0); print("AVAILABLE=" .. tostring(formatter.available)); print("AVAILABLE_MSG=" .. tostring(formatter.available_msg))' +"qall!")

assert_contains "$availability" "DECLARED=ruff_format"

if ! grep -Fq "AVAILABLE=true" <<<"$availability"; then
  skip_test "ruff_format is not available in this environment"
fi

run_headless_nvim "$temp_home" +"e $file" +'lua require("conform").format({ async = false, lsp_format = "never" })' +"wqall!"

formatted_contents=$(cat "$file")
assert_contains "$formatted_contents" "x = 1"
