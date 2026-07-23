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

"${repo_root}/dotfiles_no_term_limits/config/nvim/tests/run_tests.sh"
