FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create a test user
RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser

# Copy chezmoi source state
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

# Init and apply, then verify
RUN chezmoi init && chezmoi apply --force

# Verify expected files
RUN echo "=== Verifying dotfiles ===" \
    && test -f ~/.tmux.conf && echo "OK: .tmux.conf" \
    && test -d ~/.tmux/plugins/tpm && echo "OK: TPM installed" \
    && echo "=== All checks passed ==="
