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
provisioner="${repo_root}/setup/install_system_dependencies"

if ! rg -q 'function ubuntu_greater_than_or_equal_22_04\(\)' "$provisioner"; then
  echo >&2 "ERROR: Ubuntu 22.04 is not included in the Neovim install guard."
  exit 1
fi

if ! rg -q 'if ! ubuntu_greater_than_or_equal_22_04; then' "$provisioner"; then
  echo >&2 "ERROR: Neovim installation does not use the Ubuntu 22.04 guard."
  exit 1
fi

if ! rg -q '\[\[ "\$ubuntu_version" -ge "2204" \]\]' "$provisioner"; then
  echo >&2 "ERROR: Ubuntu version comparison does not include 22.04."
  exit 1
fi

echo "Ubuntu 22.04 installs the current Neovim release."
