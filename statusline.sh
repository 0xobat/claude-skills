#!/usr/bin/env bash
# Claude Code Status Line - Converted from PS1
# Original PS1: ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# User and hostname (green - \033[01;32m)
printf "\033[01;32m%s@%s\033[00m:" "$(whoami)" "$(hostname -s)"

# Current directory (blue - \033[01;34m) - abbreviated to home directory
dir_display="${cwd/#$HOME/~}"
printf "\033[01;34m%s\033[00m" "$dir_display"

# Git branch (if in a git repo) - purple
if [ -d "$cwd/.git" ] || git -C "$cwd" --no-optional-locks rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        printf " \033[35mon %s\033[00m" "$branch"
    fi
fi

# Model name (cyan)
printf " \033[36m[%s]\033[00m" "$model"

# Context usage (yellow if > 70%, green otherwise)
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    if [ "$used_int" -gt 70 ]; then
        printf " \033[33mctx:%s%%\033[00m" "$used_pct"
    else
        printf " \033[32mctx:%s%%\033[00m" "$used_pct"
    fi
fi
