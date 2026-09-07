#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

repo_root="$(cd -- "$(dirname "$0")/../.." >/dev/null 2>&1 && pwd -P)"
dependency_installer="${repo_root}/setup/install_system_dependencies"
zshrc="${repo_root}/dotfiles_no_term_limits/zshrc"

if rg -q '/etc/password' "$dependency_installer"; then
  echo >&2 "ERROR: shell setup checks the nonexistent /etc/password instead of /etc/passwd"
  exit 1
fi
if ! rg -q '/etc/passwd' "$dependency_installer"; then
  echo >&2 "ERROR: shell setup does not verify local users through /etc/passwd"
  exit 1
fi
if ! rg -q '/usr/share/doc/fzf/examples/key-bindings.zsh' "$zshrc"; then
  echo >&2 "ERROR: Zsh does not load Debian/Ubuntu's packaged fzf key bindings"
  exit 1
fi
if ! rg -q "bindkey -M viins '\^R'" "$zshrc"; then
  echo >&2 "ERROR: Ctrl-R is not explicitly bound in the vi insert keymap"
  exit 1
fi

echo "Login-shell setup and Ctrl-R integration are configured."
