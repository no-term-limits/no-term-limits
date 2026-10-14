# Neovim Config

Minimal config: native vim.pack, manifest-based management.

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
- Linting (ruff via `ruff server` LSP, mypy, shellcheck)
- LSP code actions: `<leader>ca` (includes ruff fixes and "Disable for this line" noqa)
- Fuzzy finding: `<leader><leader>/ff/fg/fb` (telescope)
- Theme picker: `<leader>ut` (Telescope)
- Zellij/Vim navigation: `<C-h/j/k/l>` across Neovim splits and Zellij panes
- Git integration: `<leader>gr` (reset hunk), `<leader>gp` (preview), `<leader>gb` (blame), `]c/[c` (next/prev hunk)
- Custom keymaps: `<leader>ri` (add import), `<leader>rc` (copy path), `<leader>rs/rr/rt` (tmux)
- Tooling summary: `:FileTooling` shows LSP, formatting, linting, Treesitter, and binary availability for the current file

## Theme Overrides

The repo default theme is `tokyonight-night`. To use a different default locally without changing Git state, create `~/.config/nvim/lua/config/local.lua`:

```lua
return {
  colorscheme = "kanagawa-wave",
}
```

You can still browse themes at runtime with `<leader>ut`.

## Helm Charts

Run `vpm i` to install `vim-helm` for template detection and syntax highlighting.
`setup/provision_no_term_limits` installs [helm-ls](https://github.com/mrjosh/helm-ls)
via mise. For an existing setup, run `mise use --global helm-ls@latest`.
Onboarding's `bin/install_sartography` installs `helm` and `yaml-language-server`.
If not using onboarding, install Helm separately and run
`npm install -g yaml-language-server` for embedded YAML validation.
Ensure `helm_ls`, `helm`, and `yaml-language-server` are on `$PATH`, then restart Neovim.

- Chart `templates/` files (`.yaml`, `.yml`, `.tpl`, `.txt`) use the `helm` filetype
  when the chart root contains `Chart.yaml`; `.gotmpl` files are also supported.
- Helm LSP provides completion and diagnostics, including live YAML validation
  and Kubernetes schema checks for templates; `:FileTooling` shows attachment.
  Highlighting alone does not provide diagnostics. If none appear, run
  `:lua print(vim.fn.executable('helm_ls'), vim.fn.executable('yaml-language-server'), vim.fn.executable('helm'))`
  (all should print `1`), then check `:set filetype?` reports `helm` and
  `:checkhealth vim.lsp` shows `helm_ls` attached. Schema checks require the
  Kubernetes schema to be available; custom resources need their own schema.
- `Chart.yaml` and values files retain YAML formatting. The plugin's optional
  `yaml.helm-values` filetype is also supported by Helm LSP and Prettier.
  Templates intentionally skip Prettier to avoid parsing Go template
  expressions as YAML.

## Plugins (17)

Pinned in `plugins.json`. Update with `vpm u`.

| Plugin | Purpose |
|--------|---------|
| nvim-lspconfig | LSP server configs |
| vim-helm | Helm template detection and syntax highlighting |
| nvim-treesitter | Syntax parsing |
| blink.cmp | Completion menu |
| catppuccin | Soft modern colorscheme |
| LuaSnip | Snippet engine |
| conform.nvim | Format orchestration |
| gitsigns.nvim | Git hunks/signs |
| kanagawa.nvim | Warm contrast colorscheme |
| nvim-lint | Diagnostics runner |
| plenary.nvim | Telescope utility library |
| rose-pine | Muted elegant colorscheme |
| telescope.nvim | Fuzzy picker UI |
| text-case.nvim | Case conversion |
| tokyonight.nvim | Default colorscheme |
| which-key.nvim | Keymap hint popup |
| zellij-nav.nvim | Zellij pane navigation |

## Add/Remove Plugins

**Add:** Edit `plugins.json` → `vpm i` → configure in `lua/config/plugins.lua`

**Remove:** Delete from `plugins.json` → `vpm i` (auto-cleans)
