FROM ubuntu:24.04

# Bootstrap only — just enough to run chezmoi. Everything else is installed
# by run_onchange_before_install-packages.sh.tmpl to test that it works.
RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set up UTF-8 locale (needed for Unicode/Nerd Font glyphs in tmux)
RUN sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create a test user with sudo access (needed for apt-get in run scripts)
RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER testuser
WORKDIR /home/testuser

# Copy chezmoi source state
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi

# Init and apply (run_onchange_before_ installs packages automatically)
RUN chezmoi init && chezmoi apply --force

# Verify expected files and tools
COPY --chown=testuser:testuser test.sh /home/testuser/test.sh
RUN bash /home/testuser/test.sh

SHELL ["/bin/zsh", "-c"]
CMD ["echo", "Build and verification succeeded."]
