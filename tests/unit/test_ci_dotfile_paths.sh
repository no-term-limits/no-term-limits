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
tmp_dir="$(mktemp -d -t ntl-dotfiles-XXXXXXXXXX)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

export HOME="${tmp_dir}/home"
export NO_TERM_LIMITS_DIRECTORY="$repo_root"
export NO_TERM_LIMITS_PROJECTS_DIR="${tmp_dir}/projects"
export RCRC="${repo_root}/dotfiles_no_term_limits/rcrc"
mkdir -p "$HOME" "${NO_TERM_LIMITS_PROJECTS_DIR}/github/zsh-users/zsh-autosuggestions"

rcup -f -q

expected_bashrc="${repo_root}/dotfiles_no_term_limits/bashrc"
if [[ "$(readlink "$HOME/.bashrc")" != "$expected_bashrc" ]]; then
  echo >&2 "ERROR: rcup did not use NO_TERM_LIMITS_DIRECTORY."
  exit 1
fi

ln -s \
  "${NO_TERM_LIMITS_PROJECTS_DIR}/github/zsh-users/zsh-autosuggestions" \
  "$HOME/.zsh/zsh-autosuggestions"

"${repo_root}/setup/check_dotfiles" "${repo_root}/setup/expected_dotfiles.txt"

echo "CI dotfiles honor the configured checkout and projects directories."
