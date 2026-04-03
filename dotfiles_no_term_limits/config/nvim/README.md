# Neovim Config (No Lazy)

Minimal Neovim config using native `vim.pack` with manifest-based plugin management.

## Quick Start

```bash
# Install all plugins (run once - requires cargo/rust for blink.cmp)
vpm install

# Test it works
v /tmp/test.py

# Inside nvim, run once:
:TSUpdate
```

**Note:** blink.cmp on tagged releases (like v1.10.1) auto-downloads prebuilt binaries. 
Rust/Cargo only needed if:
- You're on `main` branch (bleeding edge)
- Prebuilt download fails
- You want to customize the build

Install Rust if needed:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Features

- **LSP**: Python (pyright), TypeScript (ts_ls), JSON, YAML, Bash
- **Completion**: blink.cmp with LuaSnip snippets
- **Formatting**: conform.nvim (black, prettier, shfmt, stylua) - auto on save
- **Linting**: nvim-lint (mypy, shellcheck)
- **Fuzzy Finding**: fzf-lua (`<leader>j`, `<leader>ff`, `<leader>fg`)
- **Treesitter**: syntax highlighting
- **Text Case**: case conversion with `ga`
- **Custom keymaps**: 
  - `<leader>ri` - add Python import
  - `<leader>rb` - open code line in browser
  - `<leader>rc` - copy file path
  - `<leader>rs/rr/rt` - tmux integration

## Plugin Management

Use `vpm` (vim plugin manager) from anywhere.

### Commands

```bash
# Install all plugins from manifest
vpm install

# List installed plugins with versions
vpm list

# Update all plugins to latest
vpm update

# Update specific plugin
vpm update nvim-treesitter

# Pin a plugin to specific commit
vpm pin LuaSnip abc123

# Rebuild blink.cmp (if needed after update)
vpm build-blink

# To unpin, edit plugins.json and set commit to "latest", then run:
vpm install
```

### blink.cmp Special Notes

**Fuzzy Matching Setup:**
- **Tagged releases** (v1.10.1): Auto-downloads prebuilt binary ✓
- **Main branch**: Requires manual build: `vpm build-blink`
- Current: Pinned to `v1.10.1` (latest v1 stable)

**To use bleeding edge (main branch ~26 commits ahead):**
```bash
vpm pin blink.cmp origin/main
vpm build-blink  # Required for main branch
```

**Troubleshooting:**
- If fuzzy matching doesn't work: `vpm build-blink`
- Requires Rust/Cargo for manual builds only

### Adding a new plugin

1. Edit `~/no-term-limits/dotfiles_no_term_limits/config/nvim/plugins.json`:
```json
"plenary.nvim": {
  "repo": "nvim-lua/plenary.nvim",
  "commit": "latest"
}
```

2. Run `vpm install`

3. Configure in `lua/config/plugins.lua`

### Removing a plugin

1. Remove from `plugins.json`
2. Run `vpm install` (auto-cleans removed plugins)
3. Remove config from `lua/config/plugins.lua`

## Plugins (8 total)

| Plugin | Purpose | Pinned |
|--------|---------|--------|
| nvim-lspconfig | LSP support | latest |
| nvim-treesitter | Syntax highlighting | latest |
| blink.cmp | Completion engine | latest |
| LuaSnip | Snippet engine | latest |
| conform.nvim | Formatting | latest |
| nvim-lint | Linting | latest |
| fzf-lua | Fuzzy finding | latest |
| text-case.nvim | Case conversion | latest |

## Launch Commands

- `v` - new config (this one)
- `vo` - old LazyVim config

## Testing Setup

```bash
# Create a test file
echo 'print("hello")' > /tmp/test.py

# Open with new config
v /tmp/test.py

# Check everything loaded
:checkhealth
:LspInfo

# Test completion - type in insert mode, should see completions
# Test formatting - save file, should auto-format
```

## Directory Structure

```
nvim/
├── init.lua                    # Entry point
├── plugins.json                # Plugin manifest
├── lua/
│   └── config/
│       ├── options.lua         # Vim options
│       ├── keymaps.lua         # Key mappings
│       ├── autocmds.lua        # Autocommands
│       └── plugins.lua         # Plugin configs
├── snippets/                   # LuaSnip snippets
│   ├── python.lua
│   ├── javascript.lua
│   └── ...
└── pack/plugins/start/         # Installed plugins (managed by vpm)
```

## Notes

- Config source of truth: `~/no-term-limits/dotfiles_no_term_limits/config/nvim/`
- Also symlinked at: `~/projects/github/no-term-limits/dotfiles_no_term_limits/config/nvim/`
- Edit from either location
- `vpm` command works from anywhere
