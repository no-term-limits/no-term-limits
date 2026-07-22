#!/usr/bin/env bash

function error_handler() {
  echo >&2 "Exited with BAD EXIT CODE '${3}' in file '${1}' at line ${2}."
  exit "$3"
}
trap 'error_handler "${BASH_SOURCE[0]}" "${LINENO}" "$?"' ERR
set -o errtrace -o errexit -o nounset -o pipefail

repo_root="$(
  cd -- "$(dirname "$0")/../.." >/dev/null 2>&1
  pwd -P
)"
expected_header="$("${repo_root}/bin/bash_script_header")"
header_lines="$(printf '%s\n' "$expected_header" | awk 'END { print NR }')"
found_mismatch=false

while IFS= read -r test_file; do
  actual_header="$(head -n "$header_lines" "$test_file")"
  if [[ "$actual_header" != "$expected_header" ]]; then
    echo >&2 "ERROR: Header does not match bin/bash_script_header: ${test_file}"
    diff -u \
      <(printf '%s\n' "$expected_header") \
      <(printf '%s\n' "$actual_header") || true
    found_mismatch=true
  fi
done < <(
  rg -l '^function error_handler\(\)' \
    "${repo_root}/tests" \
    "${repo_root}/dotfiles_no_term_limits/config/nvim/tests" \
    --glob '*.sh' |
    sort -u
)

if [[ "$found_mismatch" == true ]]; then
  exit 1
fi

echo "Test script headers match bin/bash_script_header."
