#!/bin/bash
# Install Tmux Plugin Manager if not already present
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    # Install plugins defined in tmux.conf
    "$TPM_DIR/bin/install_plugins"
else
    echo "TPM already installed."
fi
