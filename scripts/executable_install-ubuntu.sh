#!/bin/bash
set -euo pipefail

# Install packages for Ubuntu/Debian.
# Safe to re-run — apt-get install and command -v checks make it idempotent.
#
# tmux and neovim are installed from source/releases (apt versions are too old).

# Resolve script directory — works both from chezmoi source and deployed ~/scripts
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Find build-tmux.sh with or without chezmoi's executable_ prefix
_find_script() {
  local name="$1"
  if [ -f "$SCRIPT_DIR/$name" ]; then echo "$SCRIPT_DIR/$name"
  elif [ -f "$SCRIPT_DIR/executable_$name" ]; then echo "$SCRIPT_DIR/executable_$name"
  else echo "$name"; fi
}

echo "Installing apt packages..."
sudo apt-get update
sudo apt-get install -y \
  curl \
  direnv \
  fd-find \
  fzf \
  ripgrep \
  git \
  git-delta \
  jq \
  just \
  unzip \
  xclip \
  zoxide \
  zsh

# fd-find installs as 'fdfind' on Ubuntu — symlink to 'fd'
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# tmux — build from source (apt version lags behind)
echo "Installing tmux from source..."
bash "$(_find_script build-tmux.sh)"

# neovim — install from GitHub releases (apt version lags behind)
if ! nvim --version 2>/dev/null | head -1 | grep -qE 'v0\.(1[1-9]|[2-9])'; then
  echo "Installing neovim from GitHub releases..."
  arch=$(uname -m)
  case "$arch" in
    x86_64)  nvim_arch="x86_64" ;;
    aarch64) nvim_arch="arm64" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
  esac
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
    | tar xz -C "$tmpdir"
  sudo rm -rf /opt/nvim
  sudo mv "$tmpdir/nvim-linux-${nvim_arch}" /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
fi

# starship (not in apt repos)
if ! command -v starship >/dev/null 2>&1; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# fnm (not in apt repos)
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

# Set default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting default shell to zsh..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

echo "Ubuntu install complete."
