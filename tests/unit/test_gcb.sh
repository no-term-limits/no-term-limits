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
tmp_dir="$(mktemp -d -t ntl-gcb-XXXXXXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

export PATH="${repo_root}/bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null

run_case() {
  local name="$1"
  local case_dir="${tmp_dir}/${name}"
  git init --quiet "$case_dir"
  (
    cd "$case_dir"
    git config user.name 'no-term-limits tests'
    git config user.email 'tests@example.invalid'
    git config core.hooksPath /dev/null
    git commit --quiet --allow-empty -m 'Initial commit'
    git branch -M main
    # No network access: simulate fetched refs for configured remotes.
    git remote add origin "${tmp_dir}/origin.git"
    git remote add loki3 "${tmp_dir}/loki3.git"

    local requested=gcp-deploy expected_branch=gcp-deploy expected_upstream=''
    local expected_error='' status=0
    case "$name" in
      local_branch)
        git branch gcp-deploy
        ;;
      origin_only)
        git update-ref refs/remotes/origin/gcp-deploy HEAD
        expected_upstream=origin/gcp-deploy
        ;;
      loki3_only|detached_start)
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        git config remote.pushDefault loki3
        expected_upstream=loki3/gcp-deploy
        if [[ "$name" == detached_start ]]; then
          git checkout --quiet --detach
        fi
        ;;
      local_over_remotes)
        git branch gcp-deploy
        git update-ref refs/remotes/origin/gcp-deploy HEAD
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        git branch --quiet --set-upstream-to=origin/gcp-deploy gcp-deploy
        expected_upstream=origin/gcp-deploy
        ;;
      explicit_remote|ambiguous_remotes)
        git update-ref refs/remotes/origin/gcp-deploy HEAD
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        git config remote.pushDefault loki3
        git config checkout.defaultRemote origin
        if [[ "$name" == explicit_remote ]]; then
          requested=loki3/gcp-deploy
          expected_upstream=loki3/gcp-deploy
        else
          expected_error='Multiple remote branches match'
        fi
        ;;
      local_suffix)
        git branch feature/gcp-deploy
        expected_branch=feature/gcp-deploy
        ;;
      nested_remote_suffix|nested_remote_full)
        git update-ref refs/remotes/loki3/feature/gcp-deploy HEAD
        expected_branch=feature/gcp-deploy
        expected_upstream=loki3/feature/gcp-deploy
        if [[ "$name" == nested_remote_full ]]; then
          requested=feature/gcp-deploy
        fi
        ;;
      ambiguous_locals)
        git branch feature/gcp-deploy
        git branch fix/gcp-deploy
        expected_error='Multiple local branches match'
        ;;
      literal_name)
        git update-ref refs/remotes/loki3/release.v1 HEAD
        git update-ref refs/remotes/origin/releasexv1 HEAD
        requested=release.v1
        expected_branch=release.v1
        expected_upstream=loki3/release.v1
        ;;
      symbolic_head)
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        git symbolic-ref refs/remotes/loki3/HEAD refs/remotes/loki3/gcp-deploy
        requested=HEAD
        expected_error='Could not find a branch'
        ;;
      missing_branch)
        expected_error='Could not find a branch'
        ;;
      tag_only)
        git tag gcp-deploy
        expected_error='Could not find a branch'
        ;;
      missing_argument)
        expected_error='usage:'
        ;;
      completion)
        git branch gcp-deploy
        git update-ref refs/remotes/origin/gcp-deploy HEAD
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        requested=auto_complete_commands
        ;;
      explicit_with_existing_local)
        git branch gcp-deploy
        git update-ref refs/remotes/loki3/gcp-deploy HEAD
        requested=loki3/gcp-deploy
        expected_error="already exists"
        ;;
    esac

    local before_head before_branch
    before_head=$(git rev-parse HEAD)
    before_branch=$(git symbolic-ref --quiet --short HEAD || true)
    if [[ "$name" == missing_argument ]]; then
      gcb > output 2>&1 || status=$?
    else
      gcb "$requested" > output 2>&1 || status=$?
    fi
    if [[ -n "$expected_error" ]]; then
      [[ "$status" -ne 0 ]]
      grep -q "$expected_error" output
      [[ "$(git rev-parse HEAD)" == "$before_head" ]]
      [[ "$(git symbolic-ref --quiet --short HEAD)" == "$before_branch" ]]
    elif [[ "$name" == completion ]]; then
      [[ "$status" -eq 0 ]]
      [[ $(grep -c '^gcp-deploy$' output) -eq 1 ]]
      [[ "$(git symbolic-ref --quiet --short HEAD)" == "$before_branch" ]]
    else
      [[ "$status" -eq 0 ]]
      [[ "$(git symbolic-ref --quiet --short HEAD)" == "$expected_branch" ]]
      [[ "$(git for-each-ref --format='%(upstream:short)' "refs/heads/$expected_branch")" == "$expected_upstream" ]]
    fi
  )
  echo "PASS: $name"
}

for scenario in \
  local_branch origin_only loki3_only detached_start local_over_remotes \
  explicit_remote ambiguous_remotes local_suffix nested_remote_suffix \
  nested_remote_full ambiguous_locals literal_name symbolic_head \
  missing_branch tag_only missing_argument completion explicit_with_existing_local; do
  run_case "$scenario"
done
