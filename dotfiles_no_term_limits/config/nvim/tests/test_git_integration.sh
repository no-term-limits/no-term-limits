#!/usr/bin/env bash

source "$(dirname "$0")/test_lib.sh"

temp_home=$(create_isolated_nvim_home)
repo_dir=$(mktemp -d -t ntl-gitsigns-repo-XXXXXXXXXX)

cleanup() {
  rm -rf "$temp_home"
  rm -rf "$repo_dir"
}
trap cleanup EXIT

cd "$repo_dir"
git init -q
git config user.email test@example.com
git config user.name test
printf 'a\n' > tracked.txt
git add tracked.txt
git commit -qm init
printf 'a\nb\n' > tracked.txt

repo_dir_real=$(
  cd "$repo_dir" >/dev/null 2>&1
  pwd -P
)

output=$(run_headless_nvim "$temp_home" +"e $repo_dir/tracked.txt" +'lua local ok=vim.wait(5000, function() return vim.b.gitsigns_status_dict ~= nil end, 100); print("ATTACHED=" .. tostring(ok)); print(vim.inspect(vim.b.gitsigns_status_dict))' +"qall!")

assert_contains "$output" "ATTACHED=true"
assert_contains "$output" "head = \"main\""
assert_contains "$output" "root = \""$repo_dir_real"\""
