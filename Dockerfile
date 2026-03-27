FROM ubuntu:24.04

# Minimal bootstrap — chezmoi's run_onchange_before_ script handles the rest
RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    sudo \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Set up UTF-8 locale (needed for Unicode/Nerd Font glyphs in tmux)
RUN sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create a test user with sudo access (needed for apt-get in run scripts)
RUN useradd -m -s /bin/zsh testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER testuser
WORKDIR /home/testuser

# Copy chezmoi source state
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

# Init and apply (run_onchange_before_ installs packages automatically)
RUN chezmoi init && chezmoi apply --force

# Verify expected files and tools
RUN echo "=== Verifying dotfiles ===" \
    && test -f ~/.tmux.conf && echo "OK: .tmux.conf" \
    && test -d ~/.tmux/plugins/tpm && echo "OK: TPM installed" \
    && test -f ~/.config/ghostty/config && echo "OK: ghostty config" \
    && test -f ~/.shellrc && echo "OK: .shellrc" \
    && test -f ~/.zshrc && echo "OK: .zshrc" \
    && test -f ~/.bashrc && echo "OK: .bashrc" \
    && test -f ~/.zprofile && echo "OK: .zprofile" \
    && command -v fzf && echo "OK: fzf installed" \
    && command -v tmux && echo "OK: tmux installed" \
    && command -v direnv && echo "OK: direnv installed" \
    && command -v nvim && echo "OK: neovim installed" \
    && echo "=== All checks passed ==="
