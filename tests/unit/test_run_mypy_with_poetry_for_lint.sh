#!/usr/bin/env bash

function error_handler() {
  >&2 echo "Exited with BAD EXIT CODE '${2}' in ${0} script at line: ${1}."
  exit "$2"
}
trap 'error_handler ${LINENO} $?' ERR
set -o errtrace -o errexit -o nounset -o pipefail

repo_root="$(
  cd -- "$(dirname "$0")/../.." >/dev/null 2>&1
  pwd -P
)"

if ! command -v uv >/dev/null 2>&1; then
  echo "Skipping: uv is not installed."
  exit 0
fi

tmp_dir=$(mktemp -d -t ntl-mypy-lint-XXXXXXXXXX)

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

project_dir="${tmp_dir}/project"
mkdir -p "$project_dir"

cat <<'EOF' >"${project_dir}/pyproject.toml"
[project]
name = "ntl-mypy-lint-test"
version = "0.0.0"
requires-python = ">=3.10"

[dependency-groups]
dev = ["mypy"]

[tool.uv]
package = false

[tool.mypy]
python_version = "3.10"
EOF

cat <<'EOF' >"${project_dir}/good.py"
def returns_number() -> int:
    return 1
EOF

cat <<'EOF' >"${project_dir}/bad.py"
def returns_number() -> int:
    return "not a number"
EOF

export PATH="${repo_root}/bin:${PATH}"

cd "$repo_root"
"${repo_root}/bin/run_mypy_with_poetry_for_lint" "${project_dir}/good.py" \
  >"${tmp_dir}/good.stdout" 2>"${tmp_dir}/good.stderr"

if "${repo_root}/bin/run_mypy_with_poetry_for_lint" "${project_dir}/bad.py" \
  >"${tmp_dir}/bad.stdout" 2>"${tmp_dir}/bad.stderr"; then
  bad_status=0
else
  bad_status=$?
fi

if [[ "$bad_status" -ne 1 ]]; then
  >&2 echo "ERROR: Expected mypy type errors to exit with status 1, got ${bad_status}"
  >&2 cat "${tmp_dir}/bad.stdout"
  >&2 cat "${tmp_dir}/bad.stderr"
  exit 1
fi

if rg -n 'poetry: command not found|BAD EXIT CODE' "${tmp_dir}/good.stderr" "${tmp_dir}/bad.stderr"; then
  >&2 echo "ERROR: Lint wrapper still leaked poetry or shell trap failures."
  exit 1
fi

if ! rg -q 'Incompatible return value type' "${tmp_dir}/bad.stdout" "${tmp_dir}/bad.stderr"; then
  >&2 echo "ERROR: Expected mypy output for the bad file."
  >&2 cat "${tmp_dir}/bad.stdout"
  >&2 cat "${tmp_dir}/bad.stderr"
  exit 1
fi

echo "run_mypy_with_poetry_for_lint works via uv and preserves mypy diagnostics."
