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
provisioner="${repo_root}/setup/provision_no_term_limits"

for tool in ruff uv; do
  if ! rg -q "mise use --global ${tool}@latest" "$provisioner"; then
    echo >&2 "ERROR: ${tool} must use its standalone mise backend."
    exit 1
  fi

  if rg -n "mise use --global pipx:${tool}" "$provisioner"; then
    echo >&2 "ERROR: ${tool} must not depend on host Python/pip through pipx."
    exit 1
  fi
done

echo "Ruff and uv use standalone mise backends."
