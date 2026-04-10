#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

require_command_or_skip uv

temp_home=$(create_isolated_nvim_home)
project_dir=$(mktemp -d -t ntl-mypy-project-XXXXXXXXXX)

cleanup() {
  rm -rf "$temp_home"
  rm -rf "$project_dir"
}
trap cleanup EXIT

cat <<'EOF' >"${project_dir}/pyproject.toml"
[project]
name = "ntl-mypy-feature-test"
version = "0.0.0"
requires-python = ">=3.10"

[dependency-groups]
dev = ["mypy"]

[tool.uv]
package = false

[tool.mypy]
python_version = "3.10"
EOF

cat <<'EOF' >"${project_dir}/bad.py"
def returns_number() -> int:
    return "not a number"
EOF

nvim_output=$(run_headless_nvim "$temp_home" +"e ${project_dir}/bad.py" +'lua local lint=require("lint"); local l=lint.linters.mypy; print("FILETYPE=" .. vim.bo.filetype); print("COMMAND=" .. tostring(l.cmd)); print("CONDITION=" .. tostring(l.condition({ filename = vim.api.nvim_buf_get_name(0) }))); print("EXECUTABLE=" .. tostring(vim.fn.executable(l.cmd) == 1)); print("LINTERS=" .. table.concat(lint.linters_by_ft.python, ","))' +"qall!")

assert_contains "$nvim_output" "FILETYPE=python"
assert_contains "$nvim_output" "COMMAND=run_mypy_with_poetry_for_lint"
assert_contains "$nvim_output" "CONDITION=true"
assert_contains "$nvim_output" "EXECUTABLE=true"
assert_contains "$nvim_output" "LINTERS=mypy"

if wrapper_output=$("${repo_root}/bin/run_mypy_with_poetry_for_lint" "${project_dir}/bad.py" 2>&1); then
  wrapper_status=0
else
  wrapper_status=$?
fi

if [[ "$wrapper_status" -ne 1 ]]; then
  >&2 echo "ERROR: Expected mypy wrapper to exit with status 1, got ${wrapper_status}"
  >&2 printf '%s\n' "$wrapper_output"
  exit 1
fi

assert_contains "$wrapper_output" "Incompatible return value type"
