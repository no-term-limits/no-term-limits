#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

repo_root="$(
  cd -- "$(dirname "$0")/../../../.." >/dev/null 2>&1
  pwd -P
)"

nvim_config_dir="${repo_root}/dotfiles_no_term_limits/config/nvim"

skip_test() {
  echo "SKIP: $*"
  exit 77
}

require_command_or_skip() {
  if ! command -v "$1" >/dev/null 2>&1; then
    skip_test "missing command: $1"
  fi
}

assert_contains() {
  local haystack=$1
  local needle=$2

  if ! grep -Fq "$needle" <<<"$haystack"; then
    >&2 echo "ERROR: expected output to contain: $needle"
    >&2 printf '%s\n' "$haystack"
    exit 1
  fi
}

assert_matches() {
  local haystack=$1
  local pattern=$2

  if ! grep -Eq "$pattern" <<<"$haystack"; then
    >&2 echo "ERROR: expected output to match regex: $pattern"
    >&2 printf '%s\n' "$haystack"
    exit 1
  fi
}

create_isolated_nvim_home() {
  local temp_home
  temp_home=$(mktemp -d -t ntl-nvim-test-XXXXXXXXXX)
  cp -R "$nvim_config_dir" "${temp_home}/nvim"
  ln -s "${HOME}/.config/nvim/pack" "${temp_home}/nvim/pack"
  printf '%s\n' "$temp_home"
}

run_headless_nvim() {
  local xdg_config_home=$1
  shift

  PATH="${repo_root}/bin:${PATH}" \
    XDG_CONFIG_HOME="$xdg_config_home" \
    nvim --headless "$@" 2>&1
}
