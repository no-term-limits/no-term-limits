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

plugins_file="${repo_root}/dotfiles_no_term_limits/config/nvim/lua/config/plugins.lua"

if rg -n 'lint\.linters\.mypy = \{' "$plugins_file"; then
  >&2 echo "ERROR: Custom mypy config replaces the built-in linter table."
  exit 1
fi

if ! rg -n 'vim\.tbl_deep_extend\("force"' "$plugins_file"; then
  >&2 echo "ERROR: Expected mypy config to extend the built-in nvim-lint definition."
  exit 1
fi

echo "Neovim mypy linter config preserves the built-in nvim-lint parser/options."
