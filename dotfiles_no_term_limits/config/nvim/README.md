# Neovim Config

Minimal config: 8 plugins, native vim.pack, manifest-based management.

## Fresh Install

**Prerequisites:** Neovim 0.11+, git, jq

```bash
git clone git@github.com:no-term-limits/no-term-limits.git ~/no-term-limits
ln -s ~/no-term-limits/dotfiles_no_term_limits/config/nvim ~/.config/nvim
cd ~/no-term-limits && ./bin/vpm i
export PATH="$HOME/no-term-limits/bin:$PATH"  # Add to ~/.zshrc
v /tmp/test.py
```

**Notes:** 
- If using rcup, `pack/` is excluded in rcrc - it's managed by `vpm`, not symlinked
- blink.cmp v1.10.1 has prebuilt binaries for Mac (both Intel & Apple Silicon) - auto-downloads on first run
- If blink shows "not compiled": check `~/.config/nvim/pack/plugins/start/blink.cmp/target/release/` for .dylib file
- If missing: `vpm build-blink` (requires Rust/Cargo)

## Daily Use

```bash
v file.py          # Open with this config
vo file.py         # Open with old LazyVim config
vpm i              # Install all plugins
vpm l              # List installed
vpm u              # Update all
vpm u nvim-lint    # Update one plugin
vpm build-blink    # If blink.cmp fuzzy not working (Mac/manual build)
```

## Features

- LSP (Python, TypeScript, JSON, YAML, Bash)
- Completion (blink.cmp + LuaSnip)
- Formatting (conform: black, prettier, shfmt) - auto on save
- Linting (mypy, shellcheck)
- Fuzzy finding: `<leader>j/ff/fg`
- Custom keymaps: `<leader>ri` (add import), `<leader>rc` (copy path), `<leader>rs/rr/rt` (tmux)

## Plugins (8)

All pinned to commits. Update with `vpm u`.

| Plugin | Purpose | Commit |
|--------|---------|--------|
| nvim-lspconfig | LSP | 8e2084b |
| nvim-treesitter | Syntax | 4916d65 |
| blink.cmp | Completion | v1.10.1 |
| LuaSnip | Snippets | 642b0c5 |
| conform.nvim | Formatting | 086a40d |
| nvim-lint | Linting | 4b03656 |
| fzf-lua | Fuzzy find | 3f19430 |
| text-case.nvim | Case convert | e898cfd |

## Add/Remove Plugins

**Add:** Edit `plugins.json` → `vpm i` → configure in `lua/config/plugins.lua`

**Remove:** Delete from `plugins.json` → `vpm i` (auto-cleans)
