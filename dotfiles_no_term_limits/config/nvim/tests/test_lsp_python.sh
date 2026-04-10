#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

require_command_or_skip pyright-langserver

temp_home=$(create_isolated_nvim_home)
project_dir=$(mktemp -d -t ntl-lsp-project-XXXXXXXXXX)

cleanup() {
  rm -rf "$temp_home"
  rm -rf "$project_dir"
}
trap cleanup EXIT

cat <<'EOF' >"${project_dir}/pyproject.toml"
[project]
name = "ntl-lsp-test"
version = "0.0.0"
EOF

printf 'x = 1\n' >"${project_dir}/test.py"

output=$(run_headless_nvim "$temp_home" +"e ${project_dir}/test.py" +'lua local ok=vim.wait(10000, function() for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if client.name == "pyright" then return true end end return false end, 100); print("LSP_READY=" .. tostring(ok)); local names = {}; for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do table.insert(names, client.name) end; table.sort(names); print("CLIENTS=" .. table.concat(names, ","))' +"qall!")

assert_contains "$output" "LSP_READY=true"
assert_contains "$output" "CLIENTS=pyright"
