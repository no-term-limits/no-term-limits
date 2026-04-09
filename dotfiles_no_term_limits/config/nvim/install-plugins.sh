#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing Neovim plugins..."

mkdir -p pack/plugins/start
cd pack/plugins/start

clone_plugin() {
  local repo=$1
  local name=$2
  
  if [ ! -d "$name" ]; then
    echo "Cloning $name..."
    git clone --depth=1 "https://github.com/$repo" "$name"
  else
    echo "$name already exists"
  fi
}

clone_plugin "neovim/nvim-lspconfig" "nvim-lspconfig"
clone_plugin "nvim-treesitter/nvim-treesitter" "nvim-treesitter"
clone_plugin "saghen/blink.cmp" "blink.cmp"
clone_plugin "L3MON4D3/LuaSnip" "LuaSnip"
clone_plugin "stevearc/conform.nvim" "conform.nvim"
clone_plugin "mfussenegger/nvim-lint" "nvim-lint"
clone_plugin "ibhagwan/fzf-lua" "fzf-lua"
clone_plugin "johmsalas/text-case.nvim" "text-case.nvim"

echo ""
echo "✓ Plugins installed!"
echo ""
echo "To pin to specific commits:"
echo "  cd pack/plugins/start/<plugin>"
echo "  git fetch --unshallow  # if cloned with --depth"
echo "  git log --oneline | head -10"
echo "  git checkout <commit-hash>"
echo ""
echo "To update a plugin:"
echo "  cd pack/plugins/start/<plugin>"
echo "  git pull"
echo ""
echo "Note: Run :TSUpdate in Neovim to install treesitter parsers"
