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

cd "$repo_root"

if rg -n 'thoughtbot/dotfiles|thoughtbot dotfiles|~/dotfiles|\$HOME/dotfiles|get_thoughtbot_dotfiles' \
  README.md \
  setup \
  dotfiles_no_term_limits; then
  echo >&2 "thoughtbot/dotfiles dependency is still present."
  exit 1
fi

echo "No thoughtbot/dotfiles dependency detected."
