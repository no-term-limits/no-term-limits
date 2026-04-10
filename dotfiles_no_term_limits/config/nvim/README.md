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
vpm                # Show help
vpm i              # Install all plugins
vpm l              # List installed
vpm u              # Update all
vpm d              # Check setup (diagnose issues)
```

## Features

- LSP (Python, TypeScript, JSON, YAML, Bash)
- Completion (blink.cmp + LuaSnip)
- Formatting (conform: black, prettier, shfmt) - auto on save
- Linting (mypy, shellcheck)
- Fuzzy finding: `<leader><leader>/ff/fg/fb` (telescope)
- Zellij/Vim navigation: `<C-h/j/k/l>` across Neovim splits and Zellij panes
- Git integration: `<leader>gr` (reset hunk), `<leader>gp` (preview), `<leader>gb` (blame), `]c/[c` (next/prev hunk)
- Custom keymaps: `<leader>ri` (add import), `<leader>rc` (copy path), `<leader>rs/rr/rt` (tmux)
- Tooling summary: `:FileTooling` shows LSP, formatting, linting, Treesitter, and binary availability for the current file

## Plugins (11)

Pinned in `plugins.json`. Update with `vpm u`.

| Plugin | Purpose |
|--------|---------|
| nvim-lspconfig | LSP server configs |
| nvim-treesitter | Syntax parsing |
| blink.cmp | Completion menu |
| LuaSnip | Snippet engine |
| conform.nvim | Format orchestration |
| gitsigns.nvim | Git hunks/signs |
| nvim-lint | Diagnostics runner |
| plenary.nvim | Telescope utility library |
| telescope.nvim | Fuzzy picker UI |
| text-case.nvim | Case conversion |
| which-key.nvim | Keymap hint popup |
| zellij-nav.nvim | Zellij pane navigation |

## Add/Remove Plugins

**Add:** Edit `plugins.json` → `vpm i` → configure in `lua/config/plugins.lua`

**Remove:** Delete from `plugins.json` → `vpm i` (auto-cleans)
