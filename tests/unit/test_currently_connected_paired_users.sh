#!/usr/bin/env bash

function error_handler() {
  echo >&2 "Exited with BAD EXIT CODE '${3}' in file '${1}' at line ${2}."
  exit "$3"
}
trap 'error_handler "${BASH_SOURCE[0]}" "${LINENO}" "$?"' ERR
set -o errtrace -o errexit -o nounset -o pipefail

script_dir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"
subject="${script_dir}/../../bin/currently_connected_paired_users"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat >"$tmp_dir/loginctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "list-sessions" ]]; then
  printf '%s\n' \
    '7 2001 burnettk - pts/7 active no -' \
    '8 1001 owner - pts/8 active no -' \
    '9 2002 other - pts/9 closing no -' \
    '10 2003 localpair seat0 tty2 active no -'
elif [[ "$1" == "show-session" ]]; then
  case "$2" in
    7) printf '%s\n' 'Name=burnettk' 'Remote=yes' 'State=active' ;;
    8) printf '%s\n' 'Name=owner' 'Remote=yes' 'State=active' ;;
    9) printf '%s\n' 'Name=other' 'Remote=yes' 'State=closing' ;;
    10) printf '%s\n' 'Name=localpair' 'Remote=no' 'State=active' ;;
  esac
fi
EOF
chmod +x "$tmp_dir/loginctl"
printf '%s\n' burnettk other localpair >"$tmp_dir/pair-users"

actual="$(
  PATH="$tmp_dir:$PATH" \
    ZELLIJ=1 \
    TMUX='' \
    NO_TERM_LIMITS_PAIR_USERS_FILE="$tmp_dir/pair-users" \
    "$subject"
)"

if [[ "$actual" != "burnettk" ]]; then
  echo >&2 "Expected only the active remote pair user; got: <$actual>"
  exit 1
fi
