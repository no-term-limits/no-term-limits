# No Term Limits - [![ci](https://github.com/no-term-limits/no-term-limits/actions/workflows/ci.yml/badge.svg)](https://github.com/no-term-limits/no-term-limits/actions/workflows/ci.yml) [![Generic badge](https://img.shields.io/badge/built%20with-science-1abc9c.svg)](https://shields.io/)


no-term[inal]-limits

 * Embrace your newly-unlimited terminal.
 * No limit to the number of programs in your $PATH.
 * No limit to the number of characters in your programs.
 * No limit to the lack of fact-checking on these statements.
 * No limit to this repo's ability to mess up your computer.
 * Limits highly desirable for U.S. congressional offices.

## What is going on here?

This is a dotfiles setup and a bunch of programs that we find useful. It "inherits" from and extends https://github.com/thoughtbot/dotfiles and is itself extendable, since it uses https://github.com/thoughtbot/rcm.

## Install

If you aren't super attached to your current dotfiles, and you are aware that it may delete stuff (backups are highly encouraged), clone this repo and run `./setup/provision_no_term_limits` or do this:

    curl -s https://raw.githubusercontent.com/no-term-limits/no-term-limits/main/setup/provision_no_term_limits -o /tmp/provision_no_term_limits && \
      chmod +x /tmp/provision_no_term_limits && \
      /tmp/provision_no_term_limits

## Help and Search

`ntlhelp` can be used to search for commands. Run without arguments for details.
Run with arguments to filter by one or more keywords (all must appear).

## TMUX

Based on https://github.com/gpakosz/.tmux

**Note**: We override `<Leader>` from `ctrl-b` to `ctrl-s`.

Common shortcuts:
  * `<Leader>\` - split pane vertically (same key as vertical bar, `|`, but you don't have to hold down shift)
  * `<Leader>-` - split pane horizontally
  * `<Leader>c` - create new window
  * `<Leader>,` - rename current window
  * `<Leader>m` - toggle mouse support (mouse is disabled by default)
  * `<Leader>[number]` - go to numbered window (indexed from 1)
  * `ctrl-h` - move focus to the pane to the left (hjkl for any direction like vim - also works with `<Leader>h`)
  * `shift-<left-arrow>` - resize current pane left (directional arrows to resize in other directions)
  * `<Leader>{` - swap current pane with the one to the left
  * `<Leader>}` - swap current pane with the one to the right

## Vim

**Note**: We override `<Leader>` from `\` to a single space.

Common shortcuts:
  * `<Leader>` - open vim-which-key, which shows all leader shortcuts
  * `<Leader>g` - show [g]it-related shortcuts
  * `<Leader>gu` - [g]it [u]ndo hunk. For a file versioned by git, remove the
    working copy change (could be multiple lines) near the cursor.
  * `<Leader>l` - show [l]anguage server protocol (lsp) related shortcuts
  * `<Leader>li` - [l]sp [i]nstall. Install the language server for the
    current filetype.
  * `<Leader>ld` - [l]sp go to [d]efinition. Goes to the definition of the term
    under the cursor.
  * `ctrl-h` - move focus to the pane to the left (hjkl for any direction like you would expect in vim)
  * `<Leader>rg` - [r]un [g]uid generator. Generates a guid and inserts it into
    your buffer.
  * `<Leader>rt` - [r]un nearest [t]est
