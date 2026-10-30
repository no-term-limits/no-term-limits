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
tmp_dir="$(mktemp -d -t ntl-gc-XXXXXXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "${tmp_dir}/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "${tmp_dir}/bin/sleep"
printf '#!/usr/bin/env bash\ntouch .git/pre-commit-check-ran\n' > "${tmp_dir}/bin/gc_pre_commit_check"
chmod +x "${tmp_dir}/bin/"*
export PATH="${tmp_dir}/bin:${repo_root}/bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export NO_TERM_LIMITS_GC_ADD_PAIRED_USERS=false
export NO_TERM_LIMITS_RUN_GIT_ADD=all
export GC_NO_VERIFY=''

run_case() {
  local name="$1" state="$2" upstream="$3" push_default="$4" expected_remote="$5"
  local command="${6:-gc}"
  local case_dir="${tmp_dir}/${name}"
  mkdir -p "$case_dir"
  for remote in origin alternate; do
    git init --bare --quiet "${case_dir}/${remote}.git"
  done
  git init --quiet "${case_dir}/source"
  (
    cd "${case_dir}/source"
    git config user.name 'no-term-limits tests'
    git config user.email 'tests@example.invalid'
    git config core.hooksPath /dev/null
    printf 'initial\n' > tracked.txt
    git add tracked.txt
    git commit --quiet -m 'Initial commit'
    git branch -M main
    for remote in origin alternate; do
      git remote add "$remote" "${case_dir}/${remote}.git"
      if [[ "$state" != new_branch ]]; then
        git push --quiet "$remote" main
      fi
    done
    if [[ -n "$upstream" ]]; then
      git branch --quiet --set-upstream-to="${upstream}/main"
    fi
    if [[ -n "$push_default" ]]; then
      git config remote.pushDefault "$push_default"
    fi

    if [[ "$state" == behind || "$state" == diverged || "$state" == other_remote_behind ]]; then
      local advanced_remote="$expected_remote"
      if [[ "$state" == other_remote_behind ]]; then
        advanced_remote=alternate
      fi
      git clone --quiet --branch main "${case_dir}/${advanced_remote}.git" "${case_dir}/other"
      (
        cd "${case_dir}/other"
        git config user.name 'other user'
        git config user.email 'other@example.invalid'
        git config core.hooksPath /dev/null
        printf 'remote change\n' > remote.txt
        git add remote.txt
        git commit --quiet -m 'Remote commit'
        git push --quiet origin main
      )
      # The source has not fetched this commit: the check must refresh remote state.
      [[ "$(git rev-parse HEAD)" == "$(git rev-parse "refs/remotes/${expected_remote}/main")" ]]
    fi
    if [[ "$state" == ahead || "$state" == diverged ]]; then
      git commit --quiet --allow-empty -m 'Local commit'
    fi
    if [[ "$state" == unavailable ]]; then
      git remote set-url "$expected_remote" "${case_dir}/missing.git"
    elif [[ "$state" == fetch_failure ]]; then
      # Allow discovery but simulate a failure when fetching the remote branch.
      mkdir -p "${case_dir}/bin"
      # Arguments must expand in the generated wrapper, not here.
      # shellcheck disable=SC2016
      printf '#!/usr/bin/env bash\nif [[ "$1" == fetch ]]; then exit 1; fi\nexec %q "$@"\n' "$(command -v git)" > "${case_dir}/bin/git"
      chmod +x "${case_dir}/bin/git"
      export PATH="${case_dir}/bin:$PATH"
    fi

    printf 'working change\n' >> tracked.txt
    printf 'untracked\n' > untracked.txt
    printf 'already staged\n' > staged.txt
    git add staged.txt
    local before_head before_index before_status status=0
    before_head=$(git rev-parse HEAD)
    before_index=$(git write-tree)
    before_status=$(git status --porcelain)
    "$command" 'Test commit' > "${case_dir}/output" 2>&1 || status=$?
    if [[ "$state" == behind || "$state" == diverged || "$state" == unavailable || "$state" == fetch_failure ]]; then
      [[ "$status" -ne 0 ]]
      [[ "$(git rev-parse HEAD)" == "$before_head" ]]
      [[ "$(git write-tree)" == "$before_index" ]]
      [[ "$(git status --porcelain)" == "$before_status" ]]
      [[ ! -e .git/pre-commit-check-ran ]]
      if [[ "$state" == behind || "$state" == diverged ]]; then
        grep -q "behind ${expected_remote}/main by 1 commit(s)" "${case_dir}/output"
      fi
    else
      [[ "$status" -eq 0 ]]
      [[ "$(git rev-parse HEAD^)" == "$before_head" ]]
      [[ "$(git log -1 --format=%s)" == 'Test commit' ]]
      [[ "$(git rev-parse HEAD)" == "$(git --git-dir="${case_dir}/${expected_remote}.git" rev-parse refs/heads/main)" ]]
      [[ -e .git/pre-commit-check-ran ]]
    fi
  )
  echo "PASS: $name"
}

run_case up_to_date current origin '' origin
run_case local_ahead ahead origin '' origin
run_case new_branch new_branch '' '' origin
run_case remote_behind behind origin '' origin
run_case diverged diverged origin '' origin
run_case no_upstream_behind behind '' '' origin
run_case upstream_remote_behind behind alternate '' alternate
run_case push_default_behind behind origin alternate alternate
run_case push_default_ignores_other_remote other_remote_behind alternate origin origin
run_case remote_unavailable unavailable origin '' origin
run_case fetch_failure fetch_failure origin '' origin
run_case gcu_behind behind origin '' origin gcu
run_case gcd_behind behind origin '' origin gcd
run_case gcf_behind behind origin '' origin gcf
