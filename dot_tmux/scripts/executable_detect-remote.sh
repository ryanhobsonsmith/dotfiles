#!/usr/bin/env bash
# Detect if the current tmux session is accessed via SSH or Docker
# and source the appropriate prefix pill conf to update the indicator.
# Called by tmux hooks: client-attached, client-detached, client-active

# Docker check (static — won't change during session lifetime)
if [ -f /.dockerenv ]; then
  tmux source-file ~/.tmux/scripts/catppuccin-prefix-docker.conf
  exit 0
fi

# SSH check — look at session environment (updated by tmux's update-environment on attach)
# Also propagate to global environment so new shells (panes/windows) inherit it,
# fixing starship hostname display and other SSH_CONNECTION checks in child shells.
ssh_val=$(tmux show-environment SSH_CONNECTION 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$ssh_val" ] && [[ "$ssh_val" != -* ]]; then
  tmux set-environment -g SSH_CONNECTION "${ssh_val#*=}"
  tmux source-file ~/.tmux/scripts/catppuccin-prefix-ssh.conf
else
  tmux set-environment -gr SSH_CONNECTION 2>/dev/null || true
  tmux source-file ~/.tmux/scripts/catppuccin-prefix.conf
fi
