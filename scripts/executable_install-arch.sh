#!/bin/bash
set -euo pipefail

# Install packages for Arch Linux / EndeavourOS.
# Safe to re-run — pacman --needed skips already-installed packages.

echo "Installing pacman packages..."
sudo pacman -Syu --needed --noconfirm \
  curl \
  direnv \
  fd \
  fzf \
  ripgrep \
  git \
  just \
  neovim \
  starship \
  tmux \
  unzip \
  zoxide \
  zsh

# fnm (not in official repos)
if ! command -v fnm >/dev/null 2>&1; then
  echo "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash
fi

# Install Node.js LTS via fnm
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"
  if ! fnm ls 2>/dev/null | grep -q "default"; then
    echo "Installing Node.js LTS via fnm..."
    fnm install --lts
    fnm default lts-latest
  fi
fi

echo "Arch install complete."
