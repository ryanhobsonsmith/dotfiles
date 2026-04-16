#!/bin/bash
set -euo pipefail

# Install packages for macOS via Homebrew.
# Safe to re-run — brew bundle and command -v checks make it idempotent.

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing Homebrew packages..."
brew bundle --file=/dev/stdin <<'EOF'
brew "age"
brew "curl"
brew "direnv"
brew "fd"
brew "fnm"
brew "ripgrep"
brew "fzf"
brew "git"
brew "git-delta"
brew "gitleaks"
brew "jq"
brew "just"
brew "neovim"
brew "pre-commit"
brew "rbenv"
brew "starship"
brew "tmux"
brew "zoxide"
brew "zsh"
cask "ghostty"
cask "font-hack"
EOF

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
  chsh -s "$(which zsh)"
fi

echo "macOS install complete."
