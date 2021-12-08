# nothing. this just overrides to obliterate the functionality in the same file in thoughtbot/dotfiles,
# mostly because stty -ixon on the first line throws stderr to the terminal, which causes this issue:

# [WARNING]: Console output during zsh initialization detected.
#
# When using Powerlevel10k with instant prompt, console output during zsh
# initialization may indicate issues.
#
# You can:
#
#   - Recommended: Change ~/.zshrc so that it does not perform console I/O
#     after the instant prompt preamble. See the link below for details.
#
#     * You will not see this error message again.
#     * Zsh will start quickly and prompt will update smoothly.
#
#   - Suppress this warning either by running p10k configure or by manually
#     defining the following parameter:
#
#       typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
#
#     * You will not see this error message again.
#     * Zsh will start quickly but prompt will jump down after initialization.
#
#   - Disable instant prompt either by running p10k configure or by manually
#     defining the following parameter:
#
#       typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
#
#     * You will not see this error message again.
#     * Zsh will start slowly.
#
#   - Do nothing.
#
#     * You will see this error message every time you start zsh.
#     * Zsh will start quickly but prompt will jump down after initialization.
#
# For details, see:
# https://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt
#
# -- console output produced during zsh initialization follows --
#
# stty: stdin isn't a terminal
# ================================================
#
# the only difference from the original thoughtbot/dotfiles file
# is that we have stty -ixon commented out since it throws stdout or stderr to the terminal
# give us access to ^Q
# stty -ixon

# vi mode
bindkey -v
bindkey "^F" vi-cmd-mode

# handy keybindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey "^Q" push-line-or-edit
bindkey -s "^T" "^[Isudo ^[A" # "t" for "toughguy"
