#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
stderr_file="${tmp_dir}/stderr"
stdout_file="${tmp_dir}/stdout"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

git -C "$tmp_dir" init >/dev/null 2>&1
git -C "$tmp_dir" checkout -b main >/dev/null 2>&1

cat <<'EOF' >"${tmp_dir}/run_test.zsh"
#!/usr/bin/env zsh

function is_mac() {
  return 1
}

function is_ubuntu() {
  return 1
}

function git_branch() {
  git branch --show-current
}

unset -f git_super_status 2>/dev/null || true
unset -f git_prompt_info 2>/dev/null || true

cd "$1"
source /home/spiffuser/projects/github/no-term-limits/dotfiles_no_term_limits/zshrc.local
git_super_status_with_fallback
EOF

chmod +x "${tmp_dir}/run_test.zsh"

zsh "${tmp_dir}/run_test.zsh" "$tmp_dir" >"$stdout_file" 2>"$stderr_file"

if [[ -s "$stderr_file" ]]; then
  >&2 echo "ERROR: Expected no stderr from git prompt fallback"
  >&2 cat "$stderr_file"
  exit 1
fi

if ! grep -q "main" "$stdout_file"; then
  >&2 echo "ERROR: Expected branch name in git prompt fallback output"
  >&2 cat "$stdout_file"
  exit 1
fi
