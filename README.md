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

This command relies on the commands having a line starting with `# HELP:`. This
line contains the contents that will be printed by ntlhelp when a command is
found.

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

## Shell (zsh is highly supported)

    > phelp
    These functions are defined in: /Users/burnettk/projects/github/no-term-limits/dotfiles_no_term_limits/zshrc.local

      c..............cd (almost) anywhere, from anywhere. For example, type "c githu<TAB>", "c no-term-limits" or even partial directory names like "c no-term"
      ra.............reloads the local shell files


    Commands in /Users/burnettk/projects/github/no-term-limits/bin:

    dssh ................... docker: popular: "ssh" into a running docker container
    gc ..................... git: popular: runs git add, git commit, and gpush. see also gcu and gcd. If paired users are connected through wemux it will add them to the commit message as collaborators as well. Add get_pair_users_for_git_commit_message command that prints out space separated list of users to customize the paired user list.
    git_copy_last_commit ... git: popular: finds last commit and copies to clipboard
    git_open_last_commit ... git: popular: finds last commit hash in log and takes you to that page in a browser
    gitc ................... git: popular: reset local repo or a given directory, removing all local changes
    gp ..................... git: popular: git pull ensuring correct branch
    gpush .................. git: popular: shortcut for "git push" while ensuring it pushes to origin with the correct branch
    gr ..................... git: popular: checks out main branch and runs git pull
    k ...................... kubernetes/k8s: popular: short for kubectl
    kd ..................... kubernetes/k8s: popular: describe a kubernetes object
    khelp .................. metahelpcommands: kubernetes/k8s: popular: search / list kubernetes commands
    ks ..................... kubernetes/k8s: popular: get all kubernetes objects for a specified app
    kssh ................... kubernetes/k8s: popular: kssh todo-app to get inside the first todo-app app-server container in the current namespace
    ktail .................. kubernetes/k8s: popular: tail the logs of a pod

## Creating new commands

Ideally commands are created with `crc` so that the command header and HELP line are added to the command.

The HELP line is needed for ntlhelp. See the "HELP and Search" section for more info.

### Common Command Header

The common command header we use forces commands to fail if any line exits badly
and traps these errors so we can print out the command name and line number on
which it failed. This makes debugging issues way easier. We prefer all commands
to have this header.

To add the header to an existing script, open the command in vim: `edc [command_name]` and type `h ctrl-j` and it will add the header.
