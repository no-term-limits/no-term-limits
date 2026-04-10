#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

script_dir="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"

pass_count=0
skip_count=0
fail_count=0

while IFS= read -r test_file; do
  echo "Running ${test_file}"
  if "$test_file"; then
    pass_count=$((pass_count + 1))
  else
    status=$?
    if [[ "$status" -eq 77 ]]; then
      skip_count=$((skip_count + 1))
    else
      fail_count=$((fail_count + 1))
    fi
  fi
done < <(find "$script_dir" -maxdepth 1 -name 'test_*.sh' ! -name 'test_lib.sh' | sort)

echo "Passed: ${pass_count}"
echo "Skipped: ${skip_count}"
echo "Failed: ${fail_count}"

if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
