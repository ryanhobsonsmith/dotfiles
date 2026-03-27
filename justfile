image := "dotfiles-test"

# Show what chezmoi would change (dry-run)
diff:
    chezmoi diff

# Check for drift between home and source state
drift:
    @echo "=== Files that differ from chezmoi source ==="
    @chezmoi verify 2>&1 && echo "No drift detected." || chezmoi diff

# Apply chezmoi source state to home (shows diff, then applies)
apply:
    chezmoi diff || true
    chezmoi apply

# Build the test Docker image
build:
    docker build -t {{image}} .

# Rebuild from scratch (no cache)
rebuild:
    docker build --no-cache -t {{image}} .

# Run tests in a clean container
test: build
    docker run --rm {{image}}

# Launch an interactive shell in a clean container
shell: build
    docker run --rm -it {{image}} /bin/zsh
