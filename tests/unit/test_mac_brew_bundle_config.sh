#!/usr/bin/env bash

function error_handler() {
  echo >&2 "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

repo_root="$(
  cd -- "$(dirname "$0")/../.." >/dev/null 2>&1
  pwd -P
)"
provisioner="${repo_root}/setup/run_fork_of_thoughtbot_laptop"

if ! rg -q 'brew bundle --no-upgrade --file=-' "$provisioner"; then
  echo >&2 "ERROR: macOS provisioning must not upgrade runner-owned formulae."
  exit 1
fi

if rg -n '^tap "(homebrew/services|thoughtbot/formulae)"' "$provisioner"; then
  echo >&2 "ERROR: macOS provisioning contains an obsolete Homebrew tap."
  exit 1
fi

if ! rg -q '^brew "neovim"$' "$provisioner"; then
  echo >&2 "ERROR: macOS provisioning must install Neovim before plugin setup."
  exit 1
fi

echo "macOS Brew Bundle installs Neovim and avoids runner upgrades and obsolete taps."
