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

# Resolve Dockerfile name for a distro
[private]
_dockerfile distro:
    @echo "Dockerfile{{ if distro == "ubuntu" { "" } else { "." + distro } }}"

# Build the test Docker image (platform: arm64, amd64; default: native)
build distro="ubuntu" platform="":
    docker build \
        {{ if platform != "" { "--platform linux/" + platform } else { "" } }} \
        -t {{image}}-{{distro}}{{ if platform != "" { "-" + platform } else { "" } }} \
        -f Dockerfile{{ if distro == "ubuntu" { "" } else { "." + distro } }} .

# Rebuild from scratch (no cache)
rebuild distro="ubuntu" platform="":
    docker build --no-cache \
        {{ if platform != "" { "--platform linux/" + platform } else { "" } }} \
        -t {{image}}-{{distro}}{{ if platform != "" { "-" + platform } else { "" } }} \
        -f Dockerfile{{ if distro == "ubuntu" { "" } else { "." + distro } }} .

# Run tests in a clean container
test distro="ubuntu" platform="": (build distro platform)
    docker run --rm \
        {{ if platform != "" { "--platform linux/" + platform } else { "" } }} \
        {{image}}-{{distro}}{{ if platform != "" { "-" + platform } else { "" } }}

# Run tests on all supported distro/platform combinations
test-all: (test "ubuntu") (test "ubuntu" "amd64") (test "arch" "amd64")

# Launch an interactive shell in a clean container
shell distro="ubuntu" platform="": (build distro platform)
    docker run --rm -it \
        {{ if platform != "" { "--platform linux/" + platform } else { "" } }} \
        {{image}}-{{distro}}{{ if platform != "" { "-" + platform } else { "" } }} /bin/zsh
