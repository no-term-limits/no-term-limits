#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

require_command_or_skip ruff

temp_home=$(create_isolated_nvim_home)
project_dir=$(mktemp -d -t ntl-ruff-project-XXXXXXXXXX)

cleanup() {
  rm -rf "$temp_home"
  rm -rf "$project_dir"
}
trap cleanup EXIT

cat <<'EOF' >"${project_dir}/pyproject.toml"
[project]
name = "ntl-ruff-test"
version = "0.0.0"
EOF

printf 'import os\n\nx = 1\n' >"${project_dir}/test.py"

cat <<'EOF' >"${project_dir}/check.lua"
local has_f401 = vim.wait(15000, function()
  for _, diagnostic in ipairs(vim.diagnostic.get(0, { lnum = 0 })) do
    if diagnostic.source == "Ruff" and diagnostic.code == "F401" then
      return true
    end
  end
  return false
end, 100)
print("RUFF_F401=" .. tostring(has_f401))

vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.lsp.buf.code_action({
  apply = true,
  filter = function(action)
    return action.title:match("Disable for this line") ~= nil
  end,
})
vim.wait(5000, function()
  return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]:match("noqa") ~= nil
end, 50)
print("LINE1=" .. vim.api.nvim_buf_get_lines(0, 0, 1, false)[1])
EOF

output=$(run_headless_nvim "$temp_home" +"e ${project_dir}/test.py" +"luafile ${project_dir}/check.lua" +"qall!")

assert_contains "$output" "RUFF_F401=true"
assert_contains "$output" "LINE1=import os  # noqa: F401"
