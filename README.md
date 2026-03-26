# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Setup

### Prerequisites

- [chezmoi](https://www.chezmoi.io/install/) installed
- [age](https://github.com/FiloSottile/age) installed (for encrypted files)
- SSH key at `~/.ssh/id_rsa` (used as age identity)

### Install on a new machine

```sh
chezmoi init <your-repo-url>
chezmoi diff    # review what will change
chezmoi apply   # apply to home directory
```

### Day-to-day usage

```sh
chezmoi add ~/.some-config     # start managing a file
chezmoi edit ~/.some-config    # edit the source version
chezmoi diff                   # preview pending changes
chezmoi apply                  # apply changes to home
chezmoi update                 # pull from remote and apply
```

## What's managed

| File | Description |
|---|---|
| `.tmux.conf` | Tmux configuration (prefix `C-a`, vim bindings, TPM plugins) |

## Testing

### Docker (Linux)

A Dockerfile is provided to validate the chezmoi config in a clean Linux environment. This tests that files are placed correctly, templates render properly, and `run_once_` scripts succeed.

```sh
docker build -t dotfiles-test .
docker run --rm dotfiles-test
```

This won't cover macOS-specific behavior (e.g. Homebrew installs, macOS defaults), but catches most issues with file placement, templates, and script errors.

Scripts that need to behave differently per OS should use platform guards:

```sh
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific
else
    # Linux / other
fi
```

### macOS testing

Docker can't run macOS. For full macOS validation, consider:

- **[Tart](https://github.com/cirruslabs/tart)** — runs macOS VMs natively on Apple Silicon. Create a clean macOS VM, clone the repo, and run `chezmoi init && chezmoi apply` for a true end-to-end test.
- **Separate macOS user account** — create a test user on your machine and init chezmoi from your repo there. Quick and free, but not fully isolated.

Tart can also be integrated into CI (e.g. GitHub Actions with a self-hosted Apple Silicon runner) for automated macOS testing if needed.
