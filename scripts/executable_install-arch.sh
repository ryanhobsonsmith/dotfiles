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
  git-delta \
  jq \
  just \
  neovim \
  starship \
  tmux \
  unzip \
  xclip \
  zellij \
  zoxide \
  zsh

# fnm (not in official repos)
if ! command -v fnm >/dev/null 2>&1; then
  echo "Installing fnm..."
  curl -fsSL https://fnm.vercel.app/install | bash
fi

# hunk (not in official repos) — only packaged via Homebrew (homebrew-core has Linux bottles)
if ! command -v hunk >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing hunk via Homebrew..."
    brew install hunk
  else
    echo "Skipping hunk: not in pacman repos, requires Homebrew (brew.sh)"
  fi
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

# Set default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting default shell to zsh..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

echo "Arch install complete."
