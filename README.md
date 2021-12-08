# No Term Limits

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

## TMUX

Based on https://github.com/gpakosz/.tmux

**Note**: We override <Leader> from ctrl-b to ctrl-s.

Common shortcuts:
  * <Leader>\ - split pane vertically
  * <Leader>- - split pane horizontally
  * <Leader>c - create new window
  * <Leader>, - rename current window
  * <Leader>m - toggle mouse support (mouse is disabled by default)
  * <Leader>[number] - go to numbered window (indexed from 1)
  * ctrl-h - move focus to the pane to the left (hjkl for any direction like vim - also works with <Leader>h)
  * shift-<left-arrow> - resize current pane left (directional arrows to resize in other directions)
