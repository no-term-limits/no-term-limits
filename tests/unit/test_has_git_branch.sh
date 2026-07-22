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
tmp_dir="$(mktemp -d -t ntl-git-branch-XXXXXXXXXX)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

git init --bare --quiet "${tmp_dir}/remote.git"
git init --quiet "${tmp_dir}/source"
git -C "${tmp_dir}/source" \
  -c user.name='no-term-limits tests' \
  -c user.email='tests@example.invalid' \
  commit --quiet --allow-empty -m 'Initial commit'
git -C "${tmp_dir}/source" branch -M main
git -C "${tmp_dir}/source" remote add origin "${tmp_dir}/remote.git"
git -C "${tmp_dir}/source" push --quiet --set-upstream origin main
git clone --quiet "${tmp_dir}/remote.git" "${tmp_dir}/checkout"

cd "${tmp_dir}/checkout"
"${repo_root}/bin/has_git_branch" main
if "${repo_root}/bin/has_git_branch" NOT_A_BRANCH_EVER; then
  echo >&2 "ERROR: NOT_A_BRANCH_EVER does not exist but has_git_branch found it."
  exit 1
fi

echo "has_git_branch detects present and missing branches in an isolated repository."
