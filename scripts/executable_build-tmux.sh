#!/bin/bash
set -euo pipefail

# Build tmux from source (latest release)
# Ubuntu's apt repos lag behind; this gets the latest version.

echo "Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y build-essential libevent-dev libncurses-dev bison pkg-config autoconf automake

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Cloning tmux..."
git clone --depth 1 https://github.com/tmux/tmux.git "$tmpdir/tmux"
cd "$tmpdir/tmux"

echo "Building tmux..."
sh autogen.sh
./configure
make -j"$(nproc)"
sudo make install

echo "Done! tmux $(tmux -V) installed."
