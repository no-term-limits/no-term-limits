#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

require_command_or_skip shellcheck

temp_home=$(create_isolated_nvim_home)
file=$(mktemp -t ntl-shellcheck-XXXX.sh)

cleanup() {
  rm -rf "$temp_home"
  rm -f "$file"
}
trap cleanup EXIT

printf '#!/usr/bin/env bash\necho $UNQUOTED\n' >"$file"

output=$(run_headless_nvim "$temp_home" +"e $file" +'lua local lint=require("lint"); lint.try_lint(); local ok=vim.wait(10000, function() return #vim.diagnostic.get(0) > 0 end, 100); print("DIAGNOSTICS_READY=" .. tostring(ok)); print("DIAG_COUNT=" .. #vim.diagnostic.get(0)); if #vim.diagnostic.get(0) > 0 then local d=vim.diagnostic.get(0)[1]; print("SOURCE=" .. tostring(d.source)); print("MESSAGE=" .. tostring(d.message)) end' +"qall!")

assert_contains "$output" "DIAGNOSTICS_READY=true"
assert_contains "$output" "DIAG_COUNT=1"
assert_contains "$output" "SOURCE=shellcheck"
assert_contains "$output" "Double quote to prevent globbing and word splitting."
