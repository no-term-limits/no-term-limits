# Fresh Machine Setup

## Prerequisites

- Neovim 0.11+ (`nvim --version`)
- git
- `jq` (for vpm)

## Setup Steps

```bash
# 1. Clone repo (wherever you want)
git clone git@github.com:no-term-limits/no-term-limits.git ~/no-term-limits
cd ~/no-term-limits

# 2. Symlink nvim config
ln -s ~/no-term-limits/dotfiles_no_term_limits/config/nvim ~/.config/nvim

# 3. Install plugins (and treesitter parsers)
./bin/vpm i

# 4. Add bin to PATH (in your ~/.zshrc or ~/.bashrc)
export PATH="$HOME/no-term-limits/bin:$PATH"

# 5. Reload shell
source ~/.zshrc

# 6. Test it
v /tmp/test.py
```

Note: `vpm install` automatically runs `:TSUpdate` to install treesitter parsers.

## That's it!

- `v` opens new config
- `vo` opens old LazyVim config  
- `vpm` manages plugins

## Optional: LazyVim Config

If you want the old LazyVim config available as `vo`:

```bash
ln -s ~/no-term-limits/dotfiles_no_term_limits/config/LazyVim ~/.config/LazyVim
```

## Troubleshooting

**blink.cmp fuzzy matching not working?**
```bash
# Should auto-download, but if it fails:
vpm build-blink  # Requires Rust/Cargo
```

**Install Rust (if needed):**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**LSPs not working?**
- Install language servers: `pyright`, `typescript-language-server`, etc.
- Or they'll be suggested when you open files
