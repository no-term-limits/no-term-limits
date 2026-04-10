#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

repo_root="$(
  cd -- "$(dirname "$0")/../.." >/dev/null 2>&1
  pwd -P
)"

"${repo_root}/dotfiles_no_term_limits/config/nvim/tests/run_tests.sh"
