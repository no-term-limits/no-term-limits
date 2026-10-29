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
tmp_dir="$(mktemp -d -t ntl-gpush-XXXXXXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

export PATH="${repo_root}/bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null

run_case() {
  local name="$1" upstream="$2" push_default="$3" expected="$4"
  local case_dir="${tmp_dir}/${name}"
  mkdir -p "$case_dir"
  for remote in origin loki3; do
    git init --bare --quiet "${case_dir}/${remote}.git"
  done
  git init --quiet "${case_dir}/source"
  (
    cd "${case_dir}/source"
    git config user.name 'no-term-limits tests'
    git config user.email 'tests@example.invalid'
    git config core.hooksPath /dev/null
    git config push.autoSetupRemote true
    git commit --quiet --allow-empty -m 'Initial commit'
    git branch -M main
    for remote in origin loki3; do
      git remote add "$remote" "${case_dir}/${remote}.git"
    done
    if [[ -n "$upstream" ]]; then
      git push --quiet --set-upstream "$upstream" main
    fi
    if [[ -n "$push_default" ]]; then
      git config remote.pushDefault "$push_default"
    fi
    git commit --quiet --allow-empty -m 'Commit to push'
    gpush
    [[ "$(git rev-parse HEAD)" == "$(git --git-dir="${case_dir}/${expected}.git" rev-parse refs/heads/main)" ]]
    # Choosing the push remote must not change git_remote's upstream behavior.
    [[ "$(git_remote 2>/dev/null)" == "${upstream:-origin}" ]]
  )
  echo "PASS: $name"
}

run_case default_without_upstream '' loki3 loki3
run_case default_overrides_upstream origin loki3 loki3
run_case upstream_without_default loki3 '' loki3
run_case origin_fallback '' '' origin
