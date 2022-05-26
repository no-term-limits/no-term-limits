#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

original_test_file="${NO_TERM_LIMITS_TESTS_DIR}/files/fix_python_docstrings.py"
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
tmp_test_file="${tmp_dir}/$(basename "$original_test_file")"
test_failed=false

cp "$original_test_file" "$tmp_test_file"
NO_TERM_LIMITS_RUN_PYTHON_FIXES=false fix_python_docstrings "$tmp_test_file"

function run_grep() {
  local pattern="$1"
  if ! grep -q "\"\"\"$pattern.\"\"\"" "$tmp_test_file" ; then
    >&2 echo "ERROR: Failed to correct ${pattern}"
    test_failed=true
  fi
}

run_grep 'ClassA'
run_grep 'fix_python_docstrings'

for test_num in a b c d e f ; do
  run_grep "Method_${test_num}"
done

if [[ "$test_failed" == true ]]; then
  >&2 echo "ERROR: tests failed. look above for failed cases"
  >&2 cat "$tmp_test_file"
  rm -rf "$tmp_test_file"
  exit 1
fi

rm -rf "$tmp_test_file"
